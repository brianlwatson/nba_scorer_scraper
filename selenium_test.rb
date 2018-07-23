require "selenium-webdriver"
require_relative "scraper.rb"
driver = Selenium::WebDriver.for :chrome
wait = Selenium::WebDriver::Wait.new(:timeout => 10)

#----------------------------------------------------------------------
#Search for player logic
#Start Loop
scraper = PlayerScraper.new()

scraper.players.each do |nba_p|
    player_name = nba_p.name
    puts "Comparing  #{player_name}"

    driver.navigate.to "http://espn.go.com"
    element = driver.find_element(id: 'global-search-trigger')
    element.click

    #Wait for homepage in case of a pop-up ad
    search_box = wait.until {
        element = driver.find_element(class: 'search-box')
        element if element.displayed?
    }
    search_box.send_keys player_name

    #Wait for search results
    search_result = wait.until {
        element = driver.find_element(class: 'search_results').find_element(class: "search_results__item").find_element(class: "search_results__link")
        element if element.displayed?
    }

    player_link = search_result.property("href")

    #Search redirects to profile, substitute in to get stats page
    #http://www.espn.com/nba/player/_/id/1966/lebron-james <- profile page from search results
    #http://www.espn.com/nba/player/stats/_/id/1966/lebron-james <- stats page
    stats_link = player_link.gsub("player/", "player/stats/")


    #------------------------------------------------------------------------
    #Navigate to stats page
    driver.navigate.to stats_link

    player_profile = driver.find_element(class: "mod-container").text
    p_name = player_profile.split(" ")[0] + " " + player_profile.split(" ")[1]


    #------------------------------------------------------------------------------
    #Get the players' stats from the last year
    #Use xpath to get all rows in the table
    cur_year = "'17-'18"
    cur_year_stats = []

    #Account for players that have additional tabs in their stats pages
    stats_rows =
        if driver.find_elements(:xpath, "//*[@id='content']/div[6]/div[1]/div/div[2]/div[1]/table/tbody/tr").length == 0
            driver.find_elements(:xpath, "//*[@id='content']/div[6]/div[1]/div/div[3]/div[1]/table/tbody/tr")
        else
            driver.find_elements(:xpath, "//*[@id='content']/div[6]/div[1]/div/div[2]/div[1]/table/tbody/tr")
        end

    stats_line = stats_rows.each_with_index do |row, index|
        next if index == 0

        #Get all the stats from the current year
        if (row.text.split(" ")[0] == cur_year)
            cur_year_stats << row.text.gsub('-', ' ')
        end
    end


    #------------------------------------------------------------------------------
    #Average the stats for the different teams a player played for
    final_stats = []
    cur_year_stats.each_with_index do |ts, index|
        ts_arr = ts.split(" ")
        if index == 0
            final_stats = ts_arr
            next
        end

        gp_cur_team = ts_arr[3].to_f

        final_stats.each_with_index do |avg, i|
            if i == 2
                final_stats[i] = ts_arr[i] + "/" + avg
            elsif i >= 3 && i < 5
                final_stats[i] = (ts_arr[i].to_f + avg.to_f)
            elsif i >= 5
                final_stats[i] = (ts_arr[i].to_f * gp_cur_team) + (avg.to_f * (final_stats[3].to_f-gp_cur_team))
            end
        end
    end

    if cur_year_stats.length > 1
        final_stats.each_with_index do |stat, index|
            if index >= 5
                final_stats[index] = (final_stats[index].to_f / final_stats[3].to_f).round(3)
            end
        end
    end

    p final_stats
    #------------------------------------------------------------------------------

    #Provide assertions for a few of the stats, just a light test, doesn't need to be all stats
    a_gp = final_stats[3]
    a_mpg = final_stats[5]
    a_pts = final_stats[23]
    a_fgp = final_stats[8]

    #Could implement unit tests and assertions later...

    success = true
    if p_name != nba_p.name
        puts "Expected #{p_name}, Actual #{nba_p.name}"
        success = false
    end

    if a_gp != nba_p.gp
        puts "Expected GP: #{a_gp}, Actual #{nba_p.gp.to_f}"
        success = false
    end
    if a_mpg != nba_p.mpg
        puts "Expected MPG: #{a_mpg}, Actual #{nba_p.mpg}"
        success = false
    end
    if a_pts != nba_p.pts
        puts "Expected Points: #{a_pts}, Actual #{nba_p.pts}"
        success = false
    end
    if a_fgp != nba_p.fg_p
        puts "Expected PG%: #{a_fgp}, Actual #{nba_p.fg_p}"
        success = false
    end

    if not success
        puts "Check failed for #{p_name}"
    else
        puts "Check passed for #{p_name}"
    end

end
    #------------------------------------------------------------------------------

driver.quit