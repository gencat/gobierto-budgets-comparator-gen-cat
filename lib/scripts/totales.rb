a = INE::Places::AutonomousRegion.find_by_slug 'castilla-la-mancha'
p = INE::Places::Province.find_by_slug 'toledo'

[160, 161].each do |code|
  (2010..2015).each do |year|

    query = {
      :query=>{
        :filtered=>{
          :filter=>{
            :bool=>{
              :must=>[
                {:term=>{:kind=>"G"}},
                {:term=>{:year=>year}},
                {:term=>{:code=>code}}
              ]
            }
          }
        }
      },
      :aggs=>{:total_budget=>{:sum=>{:field=>"amount"}}},
      :size=>10000
    }

    response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: 'functional', body: query
    total_country = response['aggregations']['total_budget']['value']

    query = {
      :query=>{
        :filtered=>{
          :filter=>{
            :bool=>{
              :must=>[
                {:term=>{:kind=>"G"}},
                {:term=>{:year=>year}},
                {:term=>{:code=>code}},
                {:term=>{:autonomy_id=>a.id}}
              ]
            }
          }
        }
      },
      :aggs=>{:total_budget=>{:sum=>{:field=>"amount"}}},
      :size=>10000
    }

    response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: 'functional', body: query
    total_autonomous_region = response['aggregations']['total_budget']['value']

    query = {
      :query=>{
        :filtered=>{
          :filter=>{
            :bool=>{
              :must=>[
                {:term=>{:kind=>"G"}},
                {:term=>{:year=>year}},
                {:term=>{:code=>code}},
                {:term=>{:province_id=>p.id}}
              ]
            }
          }
        }
      },
      :aggs=>{:total_budget=>{:sum=>{:field=>"amount"}}},
      :size=>10000
    }

    response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: 'functional', body: query
    total_province = response['aggregations']['total_budget']['value']

    puts [year, code, 'Esp', total_country].join(',')
    puts [year, code, a.name, total_autonomous_region].join(',')
    puts [year, code, p.name, total_province].join(',')
  end
end
