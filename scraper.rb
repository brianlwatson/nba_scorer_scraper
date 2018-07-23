require 'rubygems'
require 'nokogiri'
require 'open-uri'

NBA_SCORERS = "http://www.espn.com/nba/statistics/player/_/stat/scoring-per-game/sort/avgPoints/year/2018/seasontype/2"


class Player
    def initialize(name, team, gp, mpg, pts, fgm_fga, fg_p, tpm_tpa, tp_p, ftm_fta, ft_p)
        @name = name.split(',')[0]
        @pos = name.split(',')[1] 
        @team = team
        @gp = gp
        @mpg = mpg
        @pts = pts
        @fgm = fgm_fga.split('-')[0]
        @fga = fgm_fga.split('-')[1]
        @fg_p = fg_p
        @tpm = tpm_tpa.split('-')[0]
        @tpa = tpm_tpa.split('-')[1]
        @tp_p = tp_p
        @ftm = ftm_fta.split('-')[0]
        @fta = ftm_fta.split('-')[1]
        @ft_p = ft_p
    end

    attr_reader :name
    attr_reader :gp
    attr_reader :pts
    attr_reader :mpg
    attr_reader :fg_p
end

class PlayerScraper
    def initialize()
        page = Nokogiri::HTML(open(NBA_SCORERS))
        table = page.css('div#my-players-table div.mod-container div.mod-content table.tablehead tr')

        @players = []

        table.each_with_index do |player, i|
            next if i % 10 == 0 or player.css('td')[1].text == "PLAYER"
            @players << Player.new(
                player.css('td')[1].text,
                player.css('td')[2].text,
                player.css('td')[3].text,
                player.css('td')[4].text,
                player.css('td')[5].text,
                player.css('td')[6].text,
                player.css('td')[7].text,
                player.css('td')[8].text,
                player.css('td')[9].text,
                player.css('td')[10].text,
                player.css('td')[11].text,
            ) 
            end
    end

    attr_reader :players
end
