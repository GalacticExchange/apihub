
namespace :cache do
    desc "Clear options"
    task :options_clear => :environment do
      Gexcore::OptionService.cache_del_all


    end

end
