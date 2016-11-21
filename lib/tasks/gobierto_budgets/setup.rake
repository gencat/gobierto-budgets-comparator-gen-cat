namespace :gobierto_budgets do

  namespace :setup do

    SAMPLE_PLACES = %w{madrid barcelona bilbao madrigal-de-la-vera}
    SAMPLE_SITE = 'madrigal-de-la-vera'

    def indices_populated?
      GobiertoBudgets::SearchEngine.client.cluster.stats['indices']['docs']['count'] > 0
    end

    desc "Creates all indices"
    task :create_all_indices => :environment do |t, args|
      planned_db_name = 'budgets_planned'
      executed_db_name = 'budgets_executed'

      indices = %w{budgets total_budget budget_categories places debt population}
      indices.each { |index| Rake::Task["gobierto_budgets:#{index}:create"].invoke }
    end

    desc "Import supporting data. Imports Population, Places, Categories and Debt info"
    task :import_supporting_data => :environment do |t, args|
      fail "Indices are not empty" if indices_populated?
      # Create categories
      puts "Importing categories..."
      Rake::Task["gobierto_budgets:budget_categories:import"].invoke('budgets-planned')

      # Load places
      puts "Importing places..."
      Rake::Task["gobierto_budgets:places:import"].invoke

      # Load population
      puts "Importing population data..."
      (2011..2015).to_a.reverse.each do |year|
        Rake::Task["gobierto_budgets:population:import"].invoke(year.to_s,"db/data/population/#{year}.px")
        Rake::Task["gobierto_budgets:population:import"].reenable
      end

      # Load debt info
      puts "Importing debt info..."
      (2010..2015).to_a.reverse.each do |year|
        puts year
        Rake::Task["gobierto_budgets:debt:import"].invoke(year.to_s,"db/data/debt/debt-#{year}.csv")
        Rake::Task["gobierto_budgets:debt:import"].reenable
      end
    end

    desc "Imports data for sample municipalities. Good to get started"
    task :import_sample_budget_data => :environment do |t, args|
      SAMPLE_PLACES.each do |slug|
        place = INE::Places::Place.find_by_slug slug

        puts "Importing budget lines for #{place.name} (id: #{place.id})..."
        %w{budgets-planned budgets-executed}.each do |db_name|
          (2010..2015).to_a.reverse.each do |year|
            index = (db_name == 'budgets-planned') ? GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast : GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed
            %w{economic functional}.each do |area|
              ENV['place_id'] = place.id
              puts "- Executing: rake gobierto_budgets:import['#{db_name}','#{index}','#{area}','#{year}'] place_id=#{place.id}"
              Rake::Task["gobierto_budgets:budgets:import"].invoke(db_name, index, area, year.to_s)
              Rake::Task["gobierto_budgets:budgets:import"].reenable
            end
          end
        end

        puts "Importing Aggregations for #{place.name} (id: #{place.id})..."
        (2010..2015).to_a.reverse.each do |year|
          [GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed].each do |index|
              ENV['place_id'] = place.id
              puts "- Executing: rake gobierto_budgets:total_budget:import['#{index}','#{year}'] place_id=#{place.id}"
              Rake::Task["gobierto_budgets:total_budget:import"].invoke(index,year.to_s)
              Rake::Task["gobierto_budgets:total_budget:import"].reenable
          end
        end
      end
      ENV['place_id'] = nil
    end

    desc "Creates a Gobierto Site. Example: rake gobierto_budgets:setup:create_site[28079,'http://ayuntamientodemadrid.es']"
    task :create_site, [:place_id, :institution_url, :demo] => :environment do |t, args|
      place_id = args[:place_id]
      fail "Please provide a Place ID" if place_id.blank?
      fail "'#{place_id}' is not a valid place" unless INE::Places::Place.find(place_id)

      place = INE::Places::Place.find place_id
      institution_url = args[:institution_url] || "http://#{place.slug}.es"
      demo = args[:demo] || false

      site = Site.create! name: "#{place.name} Presupuestos",
                          domain: "#{place.slug}.gobierto.dev",
                          location_name: place.name,
                          location_type: place.class.name,
                          external_id: place.id,
                          institution_url: institution_url,
                          institution_type: 'Ayuntamiento'

      site.configuration.links = [institution_url]
      # site.configuration.logo = 'institution logo URL'
      site.configuration.demo = demo
      site.configuration.password_protected = false
      # Uncomment the following three lines if you want to password protect the site
      # site.configuration.password_protected = true
      # site.configuration.password_protection_username = 'demo'
      # site.configuration.password_protection_password = 'demo123'
      site.configuration.modules = ['GobiertoBudgets']
      site.save!
    end

    desc "Imports data for sample municipalities and creates sites accordingly. Good to get started"
    task :sample_site => :environment do |t, args|
      Rake::Task["gobierto_budgets:setup:create_all_indices"].invoke
      Rake::Task["gobierto_budgets:setup:import_supporting_data"].invoke
      Rake::Task["gobierto_budgets:setup:import_sample_budget_data"].invoke
      Rake::Task["gobierto_budgets:setup:create_site"].invoke('10111','http://www.madrigaldelavera.es/')
      url = Site.last.domain
      puts "Browse to #{url} to check out your sample site."
    end

  end
end
