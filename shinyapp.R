# shinyapp.R -------------------------------------------------------
library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(scales)
library(ggplot2)
install.packages("plotly")
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
#     原始文件列：region, month(或有空格), total_ridership, MR, UCL_X, LCL_X
#---------------------------
borough_spc_raw <- readr::read_csv("sixsigma_pre/all region.csv", show_col_types = FALSE)

# 列名去掉前后空格，防止 " month " 之类
names(borough_spc_raw) <- trimws(names(borough_spc_raw))

# 如果还没有名为 "month" 的列，就把第 2 列改名为 month
if (!"month" %in% names(borough_spc_raw) && ncol(borough_spc_raw) >= 2) {
  names(borough_spc_raw)[2] <- "month"
}

borough_spc <- borough_spc_raw %>%
  mutate(
    # month 形如 "Jan-24" → "01-Jan-24" → 日期
    month_date  = as.Date(paste0("01-", month), format = "%d-%b-%y"),
    month_label = month                      # 横轴标签：Jan-24, Feb-24 ...
  )

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
          p("X chart shows total monthly ridership; MR chart shows month-to-month changes."),
          
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
      h2("About this site"),
      br(),
      
      h3("Data Update"),
      p("This dashboard currently uses SPC results based on pre- and post-policy subway ridership data for four NYC boroughs (Manhattan, Brooklyn, Queens, and the Bronx)."),
      p("You can update the input CSV files and re-run the Shiny app to refresh all maps and summaries."),
      
      h3("Background"),
      p("This Shiny dashboard was developed for a Six Sigma / SPC project to study how NYC's congestion pricing policy may affect subway ridership patterns. ",
        "By combining spatial visualization with statistical process control, we highlight which stations and boroughs show the largest deviations from historical ridership baselines."),
      
      h3("Code"),
      p(
        "Code and input data used to generate this Shiny mapping tool are available on ",
        tags$a(
          "GitHub",
          href   = "https://github.com/your-org/your-repo",
          target = "_blank"
        ),
        "."
      ),
      
      h3("Methods"),
      tags$img(
        src   = "control_tests.png",  
        style = "max-width: 100%; height: auto; margin-bottom: 10px;"
      ),
      tags$small("Figure 1. Eight visual tests for special-cause variation used in our SPC analysis. We cited this figure from slides 11"),
      br(), br(),
      
      p("For each borough, we constructed SPC control charts for station-level ridership and applied the eight visual tests shown above, using both 2-sigma and 3-sigma control limits."),
      
      tags$ul(
        tags$li("Use pre-policy ridership to estimate the center line and 2σ / 3σ control limits for each station."),
        tags$li("Apply the eight SPC tests to detect special-cause variation in ridership at each station."),
        tags$li("Use 3-sigma limits to identify extreme out-of-control behaviour (large, sustained shifts or spikes)."),
        tags$li("Use 2-sigma limits as a more sensitive threshold for financial loss, capturing earlier or moderate shifts."),
        tags$li("Classify stations as ",
                tags$b("core stations"),
                " if they are out of control under both 2-sigma and 3-sigma rules, ",
                tags$b("secondary stations"),
                " if they violate only the 2-sigma rules, and ",
                tags$b("stable stations"),
                " if they show no SPC rule violations.")
      ),
      
      h3("Authors"),
      tags$ul(
        tags$li("Luyao Chang – Cornell Systems Engineering 25"),
        tags$li("Yueqing Miao – Cornell Systems Engineering 26"),
        tags$li("Kegan Lin – Cornell Systems Engineering 26"),
        tags$li("Jack Zhou – Cornell Systems Engineering 26"),
        tags$li("Laura Liu – Cornell Systems Engineering 25")
      )
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
          "Loss: ", comma(loss, accuracy = 1)
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
    paste("Core Stations:", n)
  })
  
  output$n_secondary <- renderText({
    df <- filtered_stations()
    n  <- sum(df$priority == "Secondary", na.rm = TRUE)
    paste("Secondary Stations:", n)
  })
  
  output$n_stable <- renderText({
    df <- filtered_stations()
    n  <- sum(df$priority == "Stable", na.rm = TRUE)
    paste("Stable Stations:", n)
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
      dollar(total_loss, accuracy = 1)
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
  
  # 交互版 X Chart
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
    
    p <- ggplot(df, aes(x = month_label, y = total_ridership, group = 1)) +
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
  
  # 交互版 MR Chart
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
    
    p <- ggplot(df, aes(x = month_label, y = MR, group = 1)) +
      geom_line(color = "orange", linewidth = 1, na.rm = TRUE) +
      geom_point(aes(text = tooltip), color = "darkred", size = 3, na.rm = TRUE) +
      geom_hline(yintercept = mean_MR, linetype = "dashed") +
      geom_hline(yintercept = UCL_MR, linetype = "dotted", color = "red") +
      geom_hline(yintercept = LCL_MR, linetype = "dotted", color = "red") +
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
  
  # 站点列表（Tab2-List 模式）
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
