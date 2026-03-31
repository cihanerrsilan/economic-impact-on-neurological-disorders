# ----- LIBRARIES -----
library(readr)
library(tidyverse) # Includes the dplyr, tidyr, and ggplot2 packages
library(WDI)
library(scales)
library(ggsci)
library(countrycode)
library(plotly)
library(viridis)
library(sf)          
library(rnaturalearth)    
library(rnaturalearthdata)
library(leaflet)
library(shiny)
library(plumber)

# Reading the GDP dataset
gdp_data <- read_csv("GDP_per_capita.csv")

# Reading the neurological dataset
neuro_data <- read_csv("neuro_data.csv")

glimpse(gdp_data)
glimpse(neuro_data)

# PREPARING NEURO DATA (Only 2019 and Prevalence) (Separating Autism and ADHD)
neuro_2019 <- neuro_data %>%
  filter(measure_name == "Prevalence") %>% 
  mutate(Country_Code = countrycode(location_name, "country.name", "iso3c")) %>%
  select(location_name, Country_Code, val, cause_name) %>% 
  rename(Prevalence = val, Disease = cause_name) 

# Error check: Are there any rows where a code could not be created?
print(unique(neuro_2019$location_name[is.na(neuro_2019$Country_Code)]))


# CONVERTING GDP DATA FROM "WIDE" TO "LONG" FORMAT (pivot_longer)
# It was created solely to view the format.
gdp_long <- gdp_data %>%
  select(`Country Code`, `1990`:`2020`) %>%
  pivot_longer(
    cols = -`Country Code`,
    names_to = "Year",
    values_to = "GDP"
  ) %>%
  mutate(Year = as.numeric(Year))


# PREPARING GDP DATA (Only 2019 Column)
# No need for pivot_longer anymore! We will just take the 2019 column.
gdp_2019 <- gdp_data %>%
  select(`Country Code`, `2019`) %>% 
  rename(GDP = `2019`) %>%        
  filter(!is.na(GDP))


# MERGING (JOIN)
# We merge the two tables based on Country Code.
analysis_table <- left_join(neuro_2019, gdp_2019, by = c("Country_Code" = "Country Code")) %>%
  filter(!is.na(GDP)) %>%
  mutate(Continent = countrycode(Country_Code, "iso3c", "continent")) %>%
  filter(!is.na(Continent))


# ANALYSIS: CALCULATING CORRELATION (for HTML)
# This is a single number. It is calculated for the whole world, not separately for each country.

correlation <- cor(analysis_table$GDP, analysis_table$Prevalence, use = "complete.obs")

print(paste("2019 Global Correlation Coefficient:", round(correlation, 3)))

# INTERPRETATION:
# If result is close to +1: Disease is more common in rich countries.
# If result is close to -1: Disease is more common in poor countries.
# If result is close to 0: There is no relationship between income and disease.

# REPORTING TABLE (for HTML)
# Let's sort to see and compare the richest and poorest countries side by side.
result_table <- analysis_table %>%
  arrange(desc(GDP)) %>% 
  select(location_name, GDP, Prevalence)

print(head(result_table, 10)) 
write_csv(result_table, "2019_Analysis_Results.csv")




# PREPARATION FIRST: We need to add "Continent" information to the data
# Because the Box Plot is drawn based on continents.
analysis_table <- analysis_table %>%
  mutate(Continent = countrycode(sourcevar = Country_Code,
                                 origin = "iso3c",
                                 destination = "continent")) %>%
  # Clean rows where continent information is missing (NA)
  filter(!is.na(Continent))

# VISUALIZATION 1: BOX PLOT - BY CONTINENT AND DISEASE
box_plot <- ggplot(analysis_table, aes(
  # Order continents by median disease prevalence (for better readability)
  x = reorder(Continent, Prevalence, FUN = median),
  y = Prevalence,
  fill = Continent
)) +
  geom_boxplot(
    alpha = 0.7,
    outlier.shape = 21,  # Make outliers round
    outlier.fill = "white"
  ) +
  
  # Flip the coordinates (so long continent names fit)
  coord_flip() +
  facet_wrap(~Disease, scales = "free_x") + # SEPARATING DISEASES!
  
  labs(
    title = "Neurological Disease Prevalence by Continent (2019)",
    subtitle = "Developed regions (America/Europe) report higher rates",
    x = "", # No axis label needed, continent names are already there
    y = "Disease Prevalence"
  ) +
  
  theme_minimal() +
  
  # Remove the legend (To avoid unnecessary clutter)
  theme(legend.position = "none") +
  
  # The professional color palette used in the reference code
  scale_fill_viridis_d(option = "mako")

# 1. Save Box Plot
ggsave(filename = "1_Continent_BoxPlot.png", 
       plot = box_plot, 
       width = 10, height = 6, dpi = 300)


# VISUALIZATION 2: INTERACTIVE SCATTER PLOT (GDP vs Prevalence)
scatter_static <- ggplot(analysis_table, aes(x = GDP, y = Prevalence, color = Disease)) +
  
  # Layer 1: Points (Added 'text' for interactivity)
  geom_point(
    aes(
      text = paste0(
        "Country: ", location_name,
        "<br>Continent: ", Continent,
        "<br>GDP Per Capita: $", round(GDP, 0),
        "<br>Prevalence Rate: ", round(Prevalence, 2)
      )
    ),
    alpha = 0.6,       # Transparency
    size = 2,          # Point size
    color = "steelblue" # Color
  ) +
  
  # Layer 2: Regression Line (Trend)
  geom_smooth(
    method = "lm", 
    color = "darkred", 
    se = TRUE,      # Show confidence interval (shadow)
    linetype = "dashed",
    linewidth = 1
  ) +
  
  # Axis Adjustment: Logarithmic (To balance rich-poor difference)
  scale_x_log10(labels = scales::comma) +
  facet_wrap(~Disease, scales = "free_y") + # SEPARATING DISEASES!
  
  labs(
    title = "Visibility Gap Between Economic Power and Disease",
    subtitle = "Relationship Between Economic Income and Disease",
    x = "GDP Per Capita (Logarithmic)",
    y = "Diagnosed Disease Prevalence"
  ) +
  
  theme_minimal() +
  theme(panel.grid.minor = element_blank()) + # Hide minor grid lines, keep it clean
scale_color_viridis_d(option = "turbo")

ggsave(filename = "2_GDP_Prevalence_Scatter.png", 
       plot = scatter_static, 
       width = 10, height = 6, dpi = 300)

interactive_plot <- scatter_static + 
  geom_point(aes(text = paste0(
    "Country: ", location_name,
    "<br>Continent: ", Continent,
    "<br>GDP: $", round(GDP, 0),
    "<br>Prevalence: ", round(Prevalence, 2)
  )), alpha = 0) 

# Print the screen (for HTML output)
ggplotly(interactive_plot, tooltip = "text")


# VISUALIZATION 3: FACETTING (SPLITTING INTO PANELS) (CONTINENT AND DISEASE GRID STRUCTURE)
# Logic of "facet_wrap" from PDF Page 18 and 24
facet_plot <- ggplot(analysis_table, aes(x = GDP, y = Prevalence)) +
  geom_point(alpha = 0.5, color = "darkblue", size = 1) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  scale_x_log10(labels = comma) +
  
  # MOST IMPORTANT PART: Rows are DISEASE, Columns are CONTINENT
  facet_grid(Disease ~ Continent, scales = "free_y") + 
  
  labs(
    title = "Detailed Breakdown: Relationship by Continent and Disease",
    subtitle = "How does the trend change in each continent and disease?",
    x = "GDP (Log)", y = "Prevalence"
  ) +
  theme_bw() +
  theme(strip.text = element_text(size = 8, face = "bold"))

print(facet_plot)

# 3. Save Facet Grid Plot
ggsave(filename = "3_Facet_Grid_Analysis.png", 
       plot = facet_plot, 
       width = 12, height = 8, dpi = 300)

# VISUALIZATION 4: HISTOGRAM AND DENSITY PLOTS - PDF Page 12 & 14 (SEPARATED BY DISEASE)
# PDF Page 14: Histogram
hist_plot <- ggplot(analysis_table, aes(x = Prevalence, fill = Disease)) +
  geom_histogram(bins = 30, color = "black", alpha = 0.7) +
  
  # Split into panels by disease and free the scales
  facet_wrap(~Disease, scales = "free") + 
  
  scale_fill_viridis_d(option = "turbo") +
  labs(title = "Disease Prevalence Distribution (Histogram)", x = "Prevalence", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none")

print(hist_plot)

ggsave(filename = "4_Prevalence_Histogram.png", 
       plot = hist_plot, 
       width = 10, height = 6, dpi = 300)

# PDF Page 12: Density Plot
dens_plot <- ggplot(analysis_table, aes(x = Prevalence, fill = Disease)) +
  geom_density(alpha = 0.5) +
  
  # Split into panels by disease
  facet_wrap(~Disease, scales = "free") +
  
  scale_fill_viridis_d(option = "turbo") +
  labs(title = "Disease Density Curve (Density)", x = "Prevalence", y = "Density") +
  theme_minimal() +
  theme(legend.position = "none")

print(dens_plot)

ggsave(filename = "5_Density_Plot.png", 
       plot = dens_plot, 
       width = 10, height = 6, dpi = 300)

# 1. WORLD MAP (MAPPING) - PDF 'maps_presentation.pdf' (TOTAL)
print("Downloading map data...")

# We retrieve the borders of world countries using the 'ne_countries' function.
world_map <- ne_countries(scale = "medium", returnclass = "sf")

# We match the 'Country_Code' from our 'analysis_table' with the 'iso_a3' code from the map.
map_data <- left_join(world_map, analysis_table, by = c("iso_a3" = "Country_Code"))

# DRAWING THE MAP (CHOROPLETH MAP)
print("Drawing the World Map...")

map_plot <- ggplot(data = map_data) +
  
  # Map Layer (geom_sf) - Reference: PDF Page 21
  geom_sf(aes(fill = Prevalence), color = "white", size = 0.1) +
  
  # Color Palette (Viridis - 'Magma' option highlights severity well)
  scale_fill_viridis_c(option = "magma", na.value = "gray90", direction = -1,
                       name = "Prevalence\nRate") +
  
  # Titles and Labels
  labs(
    title = "Global Neurological Disease Prevalence (2019)",
    subtitle = "Countries in gray have no available data.",
    caption = "Source: World Bank & Neurology Dataset"
  ) +
  
  # Clean Theme
  theme_minimal() +
  
  # Remove axis text (latitude-longitude) for a cleaner look
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank()
  )

# Display the Map
print(map_plot)

# SAVING THE MAP
ggsave(filename = "World_Neurology_Map.png", 
       plot = map_plot, 
       width = 12, 
       height = 6, 
       dpi = 300)

print("Map successfully saved as 'World_Neurology_Map.png'!")


# 2. WORLD MAP (SEPARATED BY DISEASE)
print("5. Drawing Map...")
world_map <- ne_countries(scale = "medium", returnclass = "sf")
map_data <- left_join(world_map, analysis_table, by = c("iso_a3" = "Country_Code")) %>% filter(!is.na(Prevalence))

map_plot <- ggplot(data = map_data) +
  geom_sf(aes(fill = Prevalence), color = "white", size = 0.1) +
  facet_wrap(~Disease, ncol = 1) + 
  scale_fill_viridis_c(option = "magma", direction = -1) +
  labs(title = "World Neurology Map (2019)") +
  theme_void() + 
  theme(legend.position = "right")

print(map_plot)

# SAVING THE MAP
ggsave(filename = "World_Neurology_Map_Separated_Disease.png", 
       plot = map_plot, 
       width = 12, 
       height = 6, 
       dpi = 300)

print("ALL PLOTS HAVE BEEN SEPARATED BY DISEASE AND SAVED!")

# INTERACTIVE WORLD MAP (PDF Page 24 - Leaflet)
# Determine colors based on disease rate (Yellow to Red)
pal <- colorNumeric(palette = "YlOrRd", domain = map_data$Prevalence)

interactive_map <- leaflet(data = map_data) %>%
  # OpenStreetMap view
  addTiles() %>%
  # Add Countries (Polygons)
  addPolygons(
    fillColor = ~pal(Prevalence),
    weight = 1,               
    opacity = 1,
    color = "white",           
    dashArray = "3",
    fillOpacity = 0.7,
    
    # Highlight when hovering
    highlightOptions = highlightOptions(
      weight = 3,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE
    ),
    
    # Info pops up when clicking (Popup/Label)
    label = ~paste0(
      "<strong>Country: </strong>", admin, 
      "<br><strong>Disease: </strong>", Disease,
      "<br><strong>Prevalence: </strong>", round(Prevalence, 2)
    ) %>% lapply(htmltools::HTML)
  ) %>%
  
  # Add Color Legend
  addLegend(pal = pal, values = ~Prevalence, opacity = 0.7, title = "Prevalence",
            position = "bottomright")

# 4. Show Map
print(interactive_map)



# STATISTICAL MODELING (PDF: Slides_SMS_2026_Part_I)
# Simple Linear Model
# Hypothesis: As GDP increases, disease prevalence increases linearly (straight line).
model_linear <- lm(Prevalence ~ GDP, data = analysis_table)

print("--- MODEL 1: SIMPLE LINEAR RESULTS ---")
summary(model_linear)


# Log-Linear Model - PDF Page 13
# Hypothesis: Disease changes as income increases exponentially (logarithmically).
# This usually yields more accurate results in economics and health data.
model_log <- lm(Prevalence ~ log(GDP), data = analysis_table)

print("--- MODEL 2: LOG-LINEAR RESULTS ---")
summary(model_log)


# Comparing Models 
# The LOWER the AIC value, the BETTER the model. (Which one is better?)
aic_linear <- AIC(model_linear)
aic_log <- AIC(model_log)

print(paste("Linear Model AIC:", round(aic_linear, 2)))
print(paste("Log Model AIC:   ", round(aic_log, 2)))

if(aic_log < aic_linear) {
  print("RESULT: The Logarithmic model explains the data better! (As expected)")
} else {
  print("RESULT: The Linear model appears better.")
}


# ADVANCED MODELING (Categorical and Interaction)
# Categorical Variable Analysis (Continent Effect) - PDF Page 28
# Question: "Even if income is the same, does the continent lived in affect the disease rate?"

model_continent <- lm(Prevalence ~ log(GDP) + Continent, data = analysis_table)

print("--- MODEL 3: CONTINENT EFFECT (Categorical) RESULTS ---")
summary(model_continent)

# Interpretation Hint: (for HTML)
# If you see stars (***) next to "ContinentEurope", 
# this means "Living in Europe significantly changes the disease rate".


# Interaction Model (Interaction Term) - PDF Page 43
# Question: "Is the effect of income on disease different for Autism and ADHD?"
# This is the "Continuous - Categorical Interaction" topic in the PDF. (for HTML)

model_interaction <- lm(Prevalence ~ log(GDP) * Disease, data = analysis_table)

print("--- MODEL 4: INTERACTION RESULTS ---")
summary(model_interaction)

# Interpretation Hint: (for HTML)
# We will look at the 'log(GDP):DiseaseAutism' line. 
# If this is significant (p < 0.05), we can say "Income increase affects Autism differently than ADHD".

# INTERACTION PLOT - PDF Page 43
# "Continuous - Categorical Interaction
ggplot(analysis_table, aes(x = GDP, y = Prevalence, color = Disease)) +
  geom_point(alpha = 0.5) +
  
  # Linear lines (Linear Fit)
  geom_smooth(method = "lm", se = TRUE) + 
  
  scale_x_log10(labels = scales::comma) +
  # Splitting into panels
  facet_wrap(~Disease, scales = "free_y") +
  
  labs(
    title = "Interaction Model: Different Responses of Diseases to Income",
    subtitle = "The difference in slopes is now clear",
    x = "GDP",
    y = "Prevalence"
  ) +
  theme_bw() +
  scale_color_viridis_d(option = "plasma")


# Which Model is Best? (AIC Comparison)
aic_table <- data.frame(
  Model = c("Simple Linear", "Logarithmic", "Continent Added", "Interactive"),
  AIC_Score = c(AIC(model_linear), AIC(model_log), AIC(model_continent), AIC(model_interaction))
)

# Find the one with the lowest AIC score and sort them
aic_table <- aic_table %>% arrange(AIC_Score)

print("--- MODEL COMPARISON TABLE (Lowest Score Wins) ---")
print(aic_table)


# QUADRATIC MODEL - PDF Page 15
# Hypothesis: Is the relationship not straight, but "U" shaped?
# Does the decline stop after a certain income level and start rising again?

# We use the I(GDP^2) command when building the model
model_quadratic <- lm(Prevalence ~ GDP + I(GDP^2), data = analysis_table)

print("--- MODEL 5: QUADRATIC RESULTS ---")
summary(model_quadratic)

# Let's add this to the AIC Comparison as well
print(paste("Quadratic Model AIC:", round(AIC(model_quadratic), 2)))

# Interpretation Hint: (for HTML)
# If the P-value (Pr>|t|) next to the I(GDP^2) line is less than 0.05,
# we can say "There is a U-shaped turn in our data."


# PLOT 1: QUADRATIC CURVE - PDF Page 15
ggplot(analysis_table, aes(x = GDP, y = Prevalence, color = Disease, fill = Disease)) +
  geom_point(alpha = 0.4) + 
  
  # Separate curved line for each disease (Quadratic Fit)
  geom_smooth(method = "lm", formula = y ~ x + I(x^2), se = TRUE, alpha = 0.2) +
  
  scale_x_log10(labels = scales::comma) +
  # Let's split into panels to see more clearly
  facet_wrap(~Disease, scales = "free_y") + 
  
  labs(
    title = "Quadratic Model: Disease-Based Analysis",
    subtitle = "Is there a 'U' turn or curve in both diseases?",
    x = "GDP (Logarithmic)",
    y = "Disease Prevalence"
  ) +
  theme_minimal() +
  scale_color_viridis_d(option = "turbo") +
  scale_fill_viridis_d(option = "turbo")


# PLOT: ACTUAL vs PREDICTED (Model Success) - (around Pages 30-32)
# First, let's get predictions from our best model (Interaction Model)
analysis_table$Prediction <- predict(model_interaction, analysis_table)

ggplot(analysis_table, aes(x = Prediction, y = Prevalence, color = Disease)) +
  geom_point(alpha = 0.6) +
  
  # Perfect prediction line
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed") +
  
  facet_wrap(~Disease, scales = "free") + # Separate!
  
  labs(
    title = "Model Success: Which Disease Was Predicted Better?",
    x = "Value Predicted by Model",
    y = "Actual Value"
  ) +
  theme_classic() +
  scale_color_viridis_d(option = "mako")

# CONTINENT and DISEASE TYPE INTERACTION (PDF Page 45)
# Question: Which continent is more "prone" to which disease?
# E.g.: Is there an ADHD boom in America, while Autism leads in Asia?

model_cat_cat <- lm(Prevalence ~ Continent * Disease, data = analysis_table)

print("CONTINENT x DISEASE INTERACTION")
summary(model_cat_cat)

# Visualize (Best understood with a Bar Plot)
ggplot(analysis_table, aes(x = Continent, y = Prevalence, fill = Disease)) +
  geom_boxplot(alpha = 0.8) + # Box plot shows the distribution
  
  labs(
    title = "Continent and Disease Interaction Analysis",
    subtitle = "Is the ratio of diseases to each other different in each continent?",
    x = "Continent",
    y = "Prevalence"
  ) +
  theme_minimal() +
  scale_fill_viridis_d(option = "plasma")


# PROGRAMMING TECHNIQUES (PDF: R_programming_presentation)
# WRITING FUNCTIONS - PDF Page 6
# Goal: Reduce repetitive tasks (e.g., Calculating Statistics) to a single line. (for HTML)
# Function Name: 'disease_summary'
# Input: Country Name

disease_summary <- function(country_name) {
  
  # 1. Find data for that country
  country_data <- analysis_table %>% filter(location_name == country_name)
  
  # 2. If data is not found, give a warning (Error Handling)
  if(nrow(country_data) == 0) {
    return("ERROR: No country found with this name!")
  }
  
  # 3. Calculate statistics
  avg_rate <- mean(country_data$Prevalence)
  income <- mean(country_data$GDP)
  risk_status <- ifelse(avg_rate > 0.6, "HIGH RISK", "Normal") # PDF Page 26 (If-Else)
  
  # 4. Print the report
  result_message <- paste0(
    "--- ", country_name, " REPORT ---\n",
    "Average Income: $", round(income, 0), "\n",
    "Disease Rate: %", round(avg_rate, 2), "\n",
    "Risk Status: ", risk_status, "\n"
  )
  
  return(cat(result_message))
}

# Let's Test the Function:
print("--- FUNCTION TEST ---")
disease_summary("Turkey")
disease_summary("United States")
disease_summary("Japan")


# INTELLIGENT CLASSIFICATION (If-Else Logic) - PDF Pages 24-26
# Goal: Automatically categorize all countries based on their income.(for HTML)
# Instead of manually writing "Rich", "Middle", "Poor", we set a rule. (for HTML)

analysis_table <- analysis_table %>%
  mutate(Economy_Class = ifelse(GDP > 40000, "Rich Country",
                                ifelse(GDP > 10000, "Middle Income", "Low Income")))

print("--- ECONOMY CLASSIFICATION ---")
table(analysis_table$Economy_Class)


# LOOPS (For Loops) - PDF Page 15
# Goal: Automatically save separate plots for each continent. (for HTML)
# We don't write "save Asia plot", "save Europe plot" one by one. (for HTML)

continents_list <- unique(analysis_table$Continent)

print("--- AUTOMATIC REPORTING STARTING (FOR LOOP) ---")

for(cont in continents_list) {
  
  # 1. Get data only for that continent
  continent_data <- analysis_table %>% filter(Continent == cont)
  
  # 2. Draw the plot
  p <- ggplot(continent_data, aes(x = GDP, y = Prevalence, color = Disease)) +
    geom_point(size = 3) +
    labs(title = paste(cont, "Continent Analysis"), x = "Income", y = "Disease") +
    theme_bw()
  
  # 3. Save the file (Create file name automatically!)
  file_name <- paste0("Auto_Report_", cont, ".png")
  ggsave(file_name, p, width = 6, height = 4)
  
  print(paste("Report created for", cont, ":", file_name))
}


# APPLY FUNCTIONS (PDF Page 19-22) (Short for loops)
# Using 'sapply' to calculate average Prevalence for each continent instantly. (for HTML)
# This is a faster alternative to loops for simple math. (for HTML)

# 1. Split data by Continent (creates a list)
continent_list <- split(analysis_table$Prevalence, analysis_table$Continent)

# 2. Apply 'mean' function to every element in the list
avg_by_continent <- sapply(continent_list, mean)

print("AVERAGE DISEASE RATE BY CONTINENT")
print(avg_by_continent)

# FINAL PROJECT: SHINY WEB APPLICATION (PDF: Shiny_presentation.pdf)
# USER INTERFACE (UI) - THE SCREEN THE USER SEES
ui <- fluidPage(
  
  # Application Title
  titlePanel("Global Neurology and Economy Analysis (2019)"),
  
  # Sidebar Layout (Left Menu)
  sidebarLayout(
    sidebarPanel(
      h3("Analysis Settings"),
      
      # Disease Selection
      selectInput("selected_disease", 
                  "Select Disease:", 
                  choices = unique(analysis_table$Disease),
                  selected = "Autism spectrum disorders"),
      
      # Continent Selection
      selectInput("selected_continent", 
                  "Select Continent:", 
                  choices = c("All", unique(analysis_table$Continent)),
                  selected = "All"),
      
      # Color Palette Selection (Extra Feature)
      radioButtons("color_palette", "Color Theme:",
                   choices = c("Viridis" = "viridis", "Magma" = "magma", "Turbo" = "turbo")),
      
      hr(),
      helpText("Data Source: World Bank & GBD 2019")
    ),
    
    # Main Panel (Right Screen)
    mainPanel(
      tabsetPanel(
        # Tab 1: Chart
        tabPanel("Chart Analysis", plotlyOutput("scatterPlot")),
        
        # Tab 2: Statistics Table
        tabPanel("Detailed Table", tableOutput("summaryTable")),
        
        # Tab 3: About
        tabPanel("About", 
                 h4("What is this Project About?"),
                 p("This application examines the relationship between Autism/ADHD prevalence and economic income."),
                 p("You can filter the data using the menu on the left."))
      )
    )
  )
)

# SERVER - BACKGROUND OPERATIONS
server <- function(input, output) {
  
  # A. Filter Data (Reactive) - PDF Page 37
  filtered_data <- reactive({
    data <- analysis_table
    
    # Disease filter
    data <- data %>% filter(Disease == input$selected_disease)
    
    # Continent filter (If "All" is not selected, then filter)
    if(input$selected_continent != "All") {
      data <- data %>% filter(Continent == input$selected_continent)
    }
    
    return(data)
  })
  
  # B. Draw Chart (Render Plotly)
  output$scatterPlot <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = GDP, y = Prevalence, color = Economy_Class)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_smooth(method = "lm", color = "black", linetype = "dashed", se = FALSE) +
      scale_x_log10() +
      scale_color_viridis_d(option = input$color_palette) + # Selected color
      labs(
        title = paste(input$selected_disease, "- Income Relationship"),
        x = "GDP Per Capita (Log)",
        y = "Disease Prevalence"
      ) +
      theme_minimal()
    
    ggplotly(p) # Make interactive
  })
  
  # C. Create Table (Render Table)
  output$summaryTable <- renderTable({
    filtered_data() %>%
      select(location_name, GDP, Prevalence, Economy_Class) %>%
      arrange(desc(GDP)) %>%
      head(10) # Show top 10 countries
  })
}

# START THE APPLICATION
#shinyApp(ui = ui, server = server)





