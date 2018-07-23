require "selenium-webdriver"
require_relative "scraper.rb"
driver = Selenium::WebDriver.for :chrome
# driver.navigate.to "http://espn.go.com"

# wait = Selenium::WebDriver::Wait.new(:timeout => 50)

# sleep 7

#----------------------------------------------------------------------
#Search for player logic
#Start Loop
scraper = PlayerScraper.new()

scraper.players.each do |nba_p|
    driver.navigate.to "http://espn.go.com"

    player_name = nba_p.name
    p player_name
    element = driver.find_element(id: 'global-search-trigger')
    element.click

    search_box = driver.find_element(class: 'search-box')
    search_box.send_keys player_name

    sleep 1

    search_result = driver.find_element(class: 'search_results').find_element(class: "search_results__item").find_element(class: "search_results__link")
    player_link = search_result.property("href")

    #Search redirects to profile, substitute in to get stats page
    #http://www.espn.com/nba/player/stats/_/id/1966/lebron-james
    #http://www.espn.com/nba/player/_/id/1966/lebron-james
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
    stats_line = driver.find_elements(:xpath, "//*[@id='content']/div[6]/div[1]/div/div[2]/div[1]/table/tbody/tr").each_with_index do |row, index|
        next if index == 0

        if (row.text.split(" ")[0] == cur_year)
            cur_year_stats << row.text.gsub('-', ' ')
        end
    end


    #------------------------------------------------------------------------------
    #Average the stats for the different teams a player played for
    final_stats = []
    cur_year_stats.each_with_index do |ts, index|
        if index == 0
            final_stats = ts.split(" ")
            next
        end

        final_stats.each_with_index do |avg, i|
            if i == 2
                final_stats[i] = ts.split(" ")[i] + "/" + avg
            elsif i >= 3
                final_stats[i] = (ts.split(" ")[i].to_f + avg.to_f)
            end
        end
    end

    if cur_year_stats.length > 1
        final_stats.each_with_index do |stat, index|
            if index >= 5
                final_stats[index] = final_stats[index].to_f / cur_year_stats.length
            end
        end
    end

    p final_stats
    #------------------------------------------------------------------------------

    #Provide assertions for a few of the stats
    a_gp = final_stats[3]
    a_mpg = final_stats[5]
    a_pts = final_stats[23]
    a_fgp = final_stats[8]

    # assert(p_name, nba_p.name, "Checking player's name -- FAILED")
    # assert(a_gp, nba_p.gp, "Checking number of games played -- FAILED")
    # assert(a_mpg, nba_p.mpg, "Checking player's minutes per game -- FAILED")
    # assert(a_pts, nba_p.pts, "Checking player's points per game -- FAILED")
    # assert(a_fgp, nba_p.fg_p, "Checking player's field goal percentage -- FAILED")

    success = true
    if p_name != nba_p.name
        puts "Expected #{p_name}, Actual #{nba_p.name}"
        success = false
    end 
    
    if a_gp != nba_p.gp
        puts "Expected GP: #{a_gp}, Actual #{nba_p.gp}"
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



#driver.quit