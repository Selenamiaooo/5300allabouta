# shinyapp.R -------------------------------------------------------
library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(scales)
library(ggplot2)
library(plotly)

#---------------------------
# 1. Load and clean station data
#---------------------------
stations <- readr::read_csv("sixsigma_pre/stationsmap.csv")

stations <- stations %>%
  select(priority, loss, borough, station_complex,
         Longitude, Latitude) %>%
  mutate(
    borough = tolower(borough),
    borough = recode(
      borough,
      "manhattan" = "Manhattan",
      "brooklyn"  = "Brooklyn",
      "queens"    = "Queens",
      "bronx"     = "Bronx"
    ),
    priority = factor(priority,
                      levels = c("Core", "Secondary", "Stable"))
  )

borough_choices <- sort(unique(stations$borough))

#---------------------------
# 1b. Load borough-level SPC data (X chart + MR chart)
#     Expected columns: region, month, total_ridership, MR, UCL_X, LCL_X
#---------------------------
borough_spc_raw <- readr::read_csv("sixsigma_pre/all region.csv",
                                   show_col_types = FALSE)

# Trim column name whitespace
names(borough_spc_raw) <- trimws(names(borough_spc_raw))

# If there is no "month" column name, rename the 2nd column to month
if (!"month" %in% names(borough_spc_raw) && ncol(borough_spc_raw) >= 2) {
  names(borough_spc_raw)[2] <- "month"
}

borough_spc <- borough_spc_raw %>%
  mutate(
    # month is something like "Jan-24"; build a proper Date for time-axis plotting
    month_date  = as.Date(paste0("01-", month), format = "%d-%b-%y"),
    month_label = month
  )

# Take the last date in the data as the last update
last_update <- borough_spc %>%
  summarise(last = max(month_date, na.rm = TRUE)) %>%
  pull(last) %>%
  format("%d %B %Y")

#---------------------------
# 2. UI
#---------------------------
ui <- navbarPage(
  title = "NYC Subway Stations Tracker Dashboard",
  id    = "mainnav",
  
  # ===== Tab 1: Station Map =====
  tabPanel(
    title = "Station Map",
    div(
      class = "outer",
      
      tags$head(
        tags$style(HTML("
          #controls {
            background-color: rgba(255, 255, 255, 0.95);
            padding: 10px 15px;
            border-radius: 6px;
            box-shadow: 0 0 8px rgba(0,0,0,0.3);
            z-index: 1000;
          }
        "))
      ),
      
      leafletOutput("map", height = "650px"),
      
      absolutePanel(
        id = "controls", class = "panel panel-default",
        top = 80, left = 20, width = 300, draggable = TRUE,
        
        h4("Borough Filter & Summary"),
        
        selectInput(
          inputId  = "borough",
          label    = "Borough:",
          choices  = borough_choices,
          selected = borough_choices[1]
        ),
        
        tags$hr(),
        h5("Station Counts (Selected Borough)"),
        
        textOutput("n_core"),
        textOutput("n_secondary"),
        textOutput("n_stable"),
        
        tags$br(),
        h5("Policy Impact (loss)"),
        
        textOutput("loss_direction"),
        textOutput("loss_value")
      )
    )
  ),
  
  # ===== Tab 2: Region Plots =====
  tabPanel(
    title = "Region Plots",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Region settings"),
        
        selectInput(
          inputId  = "region_borough",
          label    = "Borough:",
          choices  = borough_choices,
          selected = borough_choices[1]
        ),
        
        selectInput(
          inputId  = "outcome",
          label    = "Outcome:",
          choices  = c("Show SPC Control Charts" = "spc",
                       "Show Station List"       = "list"),
          selected = "spc"
        ),
        
        conditionalPanel(
          condition = "input.outcome == 'list'",
          selectInput(
            inputId = "station_type",
            label   = "Stations:",
            choices = c("Core stations"      = "Core",
                        "Secondary stations" = "Secondary",
                        "Stable stations"    = "Stable"),
            selected = "Core"
          )
        )
      ),
      
      mainPanel(
        width = 9,
        
        conditionalPanel(
          condition = "input.outcome == 'spc'",
          h3("SPC Control Charts by Borough"),
          p("The X chart shows total monthly ridership; the MR chart shows month-to-month changes on a continuous time axis (2024–2025)."),
          
          plotlyOutput("region_x_chart", height = "330px"),
          tags$hr(),
          plotlyOutput("region_mr_chart", height = "330px")
        ),
        
        conditionalPanel(
          condition = "input.outcome == 'list'",
          h3("Station list"),
          p("Display the list of stations of the selected type within the current borough."),
          tableOutput("station_list_table")
        )
      )
    )
  ),
  
  # ===== Tab 3: About this site =====
  tabPanel(
    title = "About this site",
    fluidPage(
      h2("About This Dashboard"),
      p("This dashboard provides an integrated statistical and geospatial analysis of NYC subway ridership under the context of Congestion Pricing policies. 
       It was developed as part of the Six Sigma / SPC course at Cornell University to investigate whether ridership patterns show evidence of special-cause variation."),
      br(),
      
      h3("Data Sources & Updates"),
      h5(last_update),
      p("The dashboard uses two major datasets:"),
      tags$ul(
        tags$li(
          tags$b("Station-level dataset:"),
          " Contains station complex names, boroughs, SPC classification (Core/Secondary/Stable), loss estimates, and coordinates. 
         These values come from applying SPC rules on pre-policy and post-policy ridership patterns."
        ),
        tags$li(
          tags$b("Borough-level SPC dataset:"),
          " Monthly aggregated ridership and moving range calculations from January 2024 to September 2025 for all four boroughs (Manhattan, Brooklyn, Queens, Bronx). 
         These values are used to generate X-charts and MR-charts."
        )
      ),
      p(
        "If you update the CSV files inside the ", tags$b("sixsigma_pre/"),
        " folder, the dashboard automatically refreshes all visualizations upon re-running the app."
      ),
      br(),
      
      h3("Background & Motivation"),
      p("Congestion Pricing is expected to reduce vehicle traffic in Manhattan and encourage greater use of public transit. 
       Understanding whether this shift materially affects subway ridership is crucial for estimating operational impacts, revenue implications, and downstream effects on transportation equity."),
      p("This dashboard combines spatial visualization with Statistical Process Control (SPC) to:"),
      tags$ul(
        tags$li("Detect significant changes in borough-wide ridership patterns over time."),
        tags$li("Identify stations with special-cause variation under 2-sigma and 3-sigma SPC rules."),
        tags$li("Quantify financial impacts using estimated loss models."),
        tags$li("Communicate findings using clear visuals for non-technical stakeholders.")
      ),
      br(),
      
      h3("Source Code & Repository"),
      p("All code, data files, and documentation for this dashboard are available on GitHub:"),
      tags$a(
        "NYC Subway SPC Dashboard Repository",
        href   = "https://github.com/Selenamiaooo/5300allabouta",
        target = "_blank"
      ),
      br(), br(),
      
      h3("SPC Methodology"),
      p("The dashboard implements standard SPC procedures to assess special-cause variation in subway ridership."),
      tags$img(
        src   = "control_tests.png",
        style = "max-width: 100%; height: auto; margin-bottom: 10px;"
      ),
      tags$small(
        "Figure 1. The eight visual SPC tests used to evaluate stability and detect special-cause patterns. We cited this figure from ",
        tags$a(
          "Slide 11 Lesson 5",
          href   = "https://docs.google.com/presentation/d/1d8PyyVBTx7FPnq05NzGM1_6AxN48y5EGS8bKh9p2MLw/edit?usp=sharing",
          target = "_blank"
        ),
        "."
      ),
      br(), br(),
      
      tags$ul(
        tags$li("We compute X-charts using monthly ridership totals for each borough."),
        tags$li("Moving Range (MR) charts are constructed using |X_t − X_{t−1}|."),
        tags$li("Center lines and control limits (UCL and LCL) for X-charts come from mean and MR-based variability estimates."),
        tags$li("MR control limits follow the formula: UCL = 3.268 × mean(MR), LCL = 0."),
        tags$li("We apply all eight SPC visual rules to classify special-cause variation.")
      ),
      
      p(tags$b("Station classification is defined as follows:")),
      tags$ul(
        tags$li(tags$b("Core station:"), " violates 3-sigma limits and shows persistent special-cause signals."),
        tags$li(tags$b("Secondary station:"), " violates only 2-sigma limits but shows moderate instability."),
        tags$li(tags$b("Stable station:"), " shows no SPC rule violations.")
      ),
      br(),
      
      h3("Interpreting Results"),
      tags$ul(
        tags$li("Hover over X-chart or MR-chart points to view borough, month, ridership values, and stability classification."),
        tags$li("On the map, station markers indicate instability severity using color-coded categories."),
        tags$li("Loss values represent estimated financial impact based on deviation below expected ridership baselines."),
        tags$li("Borough summaries provide counts of Core, Secondary, and Stable stations and total loss estimates.")
      ),
      br(),
      
      h3("Sources & References"),
      tags$ul(
        tags$li(
          tags$b("MTA Open Data Program: "),
          "Official open-data portal managed by the MTA Data & Analytics team, which aggregates internal transit performance and ridership datasets and publishes them for public use. ",
          tags$a(
            "https://www.mta.info/open-data",
            href   = "https://www.mta.info/open-data",
            target = "_blank"
          )
        ),
        tags$li(
          tags$b("MTA Daily Ridership Data: 2020–2025: "),
          "Systemwide daily ridership and traffic estimates for subways (including the Staten Island Railway), buses, commuter rail, and bridges and tunnels, with comparisons to pre-pandemic baselines. This dataset is used in our preprocessing to understand network-level demand shifts around congestion pricing.",
          tags$br(),
          tags$a(
            "https://data.ny.gov/Transportation/MTA-Daily-Ridership-Data-2020-2025/vxuj-8kew/about_data",
            href   = "https://data.ny.gov/Transportation/MTA-Daily-Ridership-Data-2020-2025/vxuj-8kew/about_data",
            target = "_blank"
          )
        ),
        tags$li(
          tags$b("MTA Subway Hourly Ridership: Beginning February 2022: "),
          "Hourly ridership estimates by subway station complex and fare payment class. This fine-grained dataset underlies the station-level SPC analysis and the Core/Secondary/Stable classification used in this dashboard.",
          tags$br(),
          tags$a(
            "https://catalog.data.gov/dataset/mta-subway-hourly-ridership-beginning-february-2022",
            href   = "https://catalog.data.gov/dataset/mta-subway-hourly-ridership-beginning-february-2022",
            target = "_blank"
          )
        )
      ),
      br(),
      
      h3("Authors & Contributors"),
      p("Developed by graduate students in the Cornell Systems Engineering program:"),
      tags$ul(
        tags$li("Luyao Chang – Cornell Systems Engineering ’25"),
        tags$li("Yueqing Miao – Cornell Systems Engineering ’26"),
        tags$li("Kegan Lin – Cornell Systems Engineering ’26"),
        tags$li("Jack Zhou – Cornell Systems Engineering ’26"),
        tags$li("Laura Liu – Cornell Systems Engineering ’25")
      ),
      br(),
      
      h3("Acknowledgements"),
      p("We thank the NYC MTA for providing open ridership datasets, and the Cornell Six Sigma teaching team for guidance on SPC methodology. 
       This dashboard was created for academic and educational use only.")
    )
  )
)

#---------------------------
# 3. Server
#---------------------------
server <- function(input, output, session) {
  
  # ---- Tab 1: station map ----
  filtered_stations <- reactive({
    req(input$borough)
    stations %>%
      filter(borough == input$borough)
  })
  
  output$map <- renderLeaflet({
    df <- filtered_stations()
    
    pal <- colorFactor(
      palette = c("red", "orange", "grey40"),
      domain  = levels(stations$priority)
    )
    
    leaflet(df) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -73.94, lat = 40.70, zoom = 10) %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        color = ~pal(priority),
        radius = 3,
        stroke = FALSE,
        fillOpacity = 0.8,
        label = ~paste0(
          station_complex, " (", borough, ")\n",
          "Type: ", priority, "\n",
          "Loss: ", comma(loss)
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal      = pal,
        values   = ~priority,
        title    = "Station type",
        opacity  = 1
      )
  })
  
  output$n_core <- renderText({
    df <- filtered_stations()
    n  <- sum(df$priority == "Core", na.rm = TRUE)
    paste0("🔴 Core Station: ", n)
  })
  
  output$n_secondary <- renderText({
    df <- filtered_stations()
    n  <- sum(df$priority == "Secondary", na.rm = TRUE)
    paste0("🟠 Secondary Station: ", n)
  })
  
  output$n_stable <- renderText({
    df <- filtered_stations()
    n  <- sum(df$priority == "Stable", na.rm = TRUE)
    paste0("⚪ Stable Station: ", n)
  })
  
  
  output$loss_direction <- renderText({
    df <- filtered_stations()
    total_loss <- sum(df$loss, na.rm = TRUE)
    
    if (total_loss > 0) {
      "Total loss after policy INCREASED in this borough."
    } else if (total_loss < 0) {
      "Total loss after policy DECREASED in this borough."
    } else {
      "Total loss after policy stayed roughly the same."
    }
  })
  
  output$loss_value <- renderText({
    df <- filtered_stations()
    total_loss <- sum(df$loss, na.rm = TRUE)
    paste(
      "Total loss (sum over stations):",
      dollar(total_loss)
    )
  })
  
  # ---- Tab 2: region plots / lists ----
  region_stations <- reactive({
    req(input$region_borough)
    stations %>%
      filter(borough == input$region_borough)
  })
  
  region_spc_data <- reactive({
    req(input$region_borough)
    
    borough_spc %>%
      filter(region == input$region_borough) %>%
      arrange(month_date)
  })
  
  # Interactive X Chart (time axis)
  output$region_x_chart <- renderPlotly({
    req(input$outcome == "spc")
    df <- region_spc_data()
    req(nrow(df) > 0)
    
    df <- df %>%
      mutate(
        flag = dplyr::case_when(
          total_ridership > UCL_X ~ "Above UCL",
          total_ridership < LCL_X ~ "Below LCL",
          TRUE                    ~ "Within limits"
        ),
        tooltip = paste0(
          "Borough: ", region, "<br>",
          "Month: ", month_label, "<br>",
          "Total ridership: ", scales::comma(total_ridership), "<br>",
          "Status: ", flag
        )
      )
    
    center_line <- mean(df$total_ridership, na.rm = TRUE)
    ucl_x       <- df$UCL_X[1]
    lcl_x       <- df$LCL_X[1]
    
    p <- ggplot(df, aes(x = month_date, y = total_ridership, group = 1)) +
      geom_line(color = "#0072B2", linewidth = 1, na.rm = TRUE) +
      geom_point(aes(color = flag, text = tooltip), size = 3, na.rm = TRUE) +
      scale_color_manual(
        values = c(
          "Within limits" = "grey40",
          "Above UCL"     = "orange",
          "Below LCL"     = "red"
        )
      ) +
      geom_hline(yintercept = center_line, linetype = "dashed") +
      geom_hline(yintercept = ucl_x,       linetype = "dotted", color = "red") +
      geom_hline(yintercept = lcl_x,       linetype = "dotted", color = "red") +
      scale_x_date(
        date_labels = "%Y-%m",
        date_breaks = "2 months",
        expand = expansion(mult = 0.02)
      ) +
      labs(
        title = paste("X Chart —", input$region_borough),
        x     = "Month",
        y     = "Total ridership",
        color = "Status"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title  = element_text(hjust = 0.5, face = "bold")
      )
    
    ggplotly(p, tooltip = "text")
  })
  
  # Interactive MR Chart (time axis)
  output$region_mr_chart <- renderPlotly({
    req(input$outcome == "spc")
    df <- region_spc_data()
    req(nrow(df) > 0)
    
    mean_MR <- mean(df$MR, na.rm = TRUE)
    UCL_MR  <- 3.268 * mean_MR
    LCL_MR  <- 0
    
    df <- df %>%
      mutate(
        tooltip = paste0(
          "Borough: ", region, "<br>",
          "Month: ", month_label, "<br>",
          "Moving range: ", scales::comma(MR)
        )
      )
    
    p <- ggplot(df, aes(x = month_date, y = MR, group = 1)) +
      geom_line(color = "orange", linewidth = 1, na.rm = TRUE) +
      geom_point(aes(text = tooltip), color = "darkred", size = 3, na.rm = TRUE) +
      geom_hline(yintercept = mean_MR, linetype = "dashed") +
      geom_hline(yintercept = UCL_MR,  linetype = "dotted", color = "red") +
      geom_hline(yintercept = LCL_MR,  linetype = "dotted", color = "red") +
      scale_x_date(
        date_labels = "%Y-%m",
        date_breaks = "2 months",
        expand = expansion(mult = 0.02)
      ) +
      labs(
        title = paste("Moving Range (MR) —", input$region_borough),
        x     = "Month",
        y     = "Moving range"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title  = element_text(hjust = 0.5, face = "bold")
      )
    
    ggplotly(p, tooltip = "text")
  })
  
  # Station list (Tab 2, list mode)
  output$station_list_table <- renderTable({
    req(input$outcome == "list", input$station_type)
    
    df <- region_stations() %>%
      filter(priority == input$station_type) %>%
      arrange(station_complex)
    
    data.frame(
      Number            = seq_len(nrow(df)),
      `Station complex` = df$station_complex,
      check.names       = FALSE
    )
  })
}

#---------------------------
# 4. Run app
#---------------------------
shinyApp(ui = ui, server = server)
