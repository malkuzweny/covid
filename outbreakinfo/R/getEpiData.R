#' @title Retrieve epidemiological data from outbreak.info
#'
#' @description Retrieve up-to-date epidemiological data from outbreak.info according to user specifications
#'
#' @param name: vector of location names
#' @param location_id: vector of ISO3 code representing locations
#' @param wb_region: World Bank region name(s)
#' @param country_name: country name(s)
#' @param state_name: state name(s)
#' @param admin_level: an integer representing an administrative level (World Bank regions = -1, countries = 0, states/provinces = 1, metropolitan areas = 1.5, counties = 2)
#' @param date: date(s) (YYYY-MM-DD)
#' @param mostRecent: T/F
#' @param fields: vector of API fields to include in results
#' @param sort: parameter to sort results by
#' @param size: size
#'
#' @return dataframe
#'
#' @examples
#' getEpiData(name="United States of America", date="2020-07-01")
#'
#' @export
#' @import jsonlite
#' @import progress
#'

getEpiData <- function(name=NULL, location_id=NULL, wb_region=NULL, country_name=NULL, state_name=NULL, admin_level=NULL, date=NULL, mostRecent=NULL, fields=NULL, sort=NULL, size=1000){
  q <- c()
  if(!is.null(name)){
    q <- c(q, paste0("(name:%22", paste(name, collapse="%22%20OR%20name:%22"), "%22)%20AND%20"))
  }
  if(!is.null(location_id)){
    q <- c(q, paste0("(location_id:%22", paste(location_id, collapse="%22%20OR%20location_id:%22"), "%22)%20AND%20"))
  }
  if(!is.null(wb_region)){
    q <- c(q, paste0("(wb_region:%22", paste(wb_region, collapse="%22%20OR%20wb_region:%22"), "%22)%20AND%20"))
  }
  if(!is.null(country_name)){
    q <- c(q, paste0("(country_name:%22", paste(country_name, collapse="%22%20OR%20country_name:%22"), "%22)%20AND%20"))
  }
  if(!is.null(state_name)){
    q <- c(q, paste0("(state_name:%22", paste(state_name, collapse="%22%20OR%20state_name:%22"), "%22)%20AND%20"))
  }
  if(!is.null(admin_level)){
    q <- c(q, paste0("(admin_level:%22", paste(admin_level, collapse="%22%20OR%20admin_level:%22"), "%22)%20AND%20"))
  }
  if(!is.null(date)){
    if (!is.character(date)){
      stop("Date must be in string format")
    }else{
      q <- c(q, paste0("(date:%22", paste(date, collapse="%22%20OR%20date:%22"), "%22)%20AND%20"))
    }
  }
  q <- paste(q, sep="", collapse = "")
  q <- substr(q, 1, nchar(q)-9)
  if(!is.null(mostRecent)){
    if (!is.logical(mostRecent)){
      stop("mostRecent must be in Boolean format")
    }else{
      q <- c(q, paste0("%20AND%20", "mostRecent:", tolower(mostRecent)))
    }
  }
  q <- paste(q, sep="", collapse = "")
  q <- gsub("&", "%26", q)
  if(!is.null(fields)){
    q <- c(q, paste0("&fields=", paste(fields, collapse=",")))
  }
  if(!is.null(sort)){
    q <- c(q, paste0("&sort=", paste(sort)))
  }

  q <- c(q, paste0("&size=", paste(size)))
  q <- paste(q, sep="", collapse = "")
  q <- paste0(q, "&fetch_all=true")
  q <- gsub(" ", "+", q)

  dataurl <- paste0(api.url, "query?q=", q)
  resp <- fromJSON(dataurl, flatten=TRUE)
  max <- resp$total

  scroll.id <- NULL
  results <- list()
  success <- NULL
  pb <- progress_bar$new(
    format = "  downloading [:bar] :percent eta: :eta",
    total = max, clear = FALSE, width= 60)
  pb$tick(0)
  while(is.null(success)){
    dataurl <- paste0(api.url, "query?q=", q)
    dataurl <- ifelse(is.null(scroll.id), dataurl, paste0(dataurl, "&scroll_id=", scroll.id))
    resp <- fromJSON(dataurl, flatten=TRUE)
    scroll.id <- resp$'_scroll_id'
    results[[length(results) + 1]] <- resp$hits
    success <- resp$success
    if (is.null(success)){
      pb$tick(size)
    }else{
      pb$finished <- T
    }
  }
  pb$terminate()
  if(length(results) > 1){
    hits <- rbind_pages(results)
  }else{
    hits <- data.frame(results)
  }
  if ("date" %in% colnames(hits)){
    hits$date=as.Date(hits$date, "%Y-%m-%d")
  }
  return(hits)
}
