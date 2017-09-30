namespace :gexcore do


  # services fx

  desc 'fix old services - add service type'
  task :fx_old_services do

    all_cluster_services = ClusterService.w_not_deleted.all

    all_cluster_services.each do |service|
      lib_serv = LibraryService.get_by_name(service.name)

      if lib_serv
        service.type_name = lib_serv.type.name
      else
        service.type_name = 'custom'
      end

      res = service.save

      if res
        puts "#{service.name} now has type #{service.type_name}"
      else
        puts "update #{service.name} failed"
      end

    end

  end







  desc 'Update AWS'
  task :update_aws_relations do
    Rake::Task["gexcore:update_aws_instance_types"].invoke
    Rake::Task["gexcore:mark_deprecated_aws_instance_types"].invoke
    Rake::Task["gexcore:create_aws_dependencies"].invoke
  end

  desc 'Load AWS instance types from csv file'
  task :update_aws_instance_types do
    csv = CSV.read('aws_regions.csv')
    instance_types = []

    # get all instance types for us-east-1
    csv.each do |row|
      instance_types << row[0]
    end

    # remove region name
    instance_types.shift

    instance_types.each do |aws_it|
      AwsInstanceType.where(name: aws_it).first_or_create
    end

  end

  desc 'Mark deprecated AWS instance types'
  task :mark_deprecated_aws_instance_types do
    csv = CSV.read('aws_regions.csv')
    instance_types = []

    # get all instance types for us-east-1
    csv.each do |row|
      instance_types << row[0]
    end
    # remove region name
    instance_types.shift

    aws_instance_types = AwsInstanceType.all

    aws_instance_types.each do |aws_it|
      deprecated = !(instance_types.include? aws_it.name)

      if deprecated
        aws_it.deprecated = true
        aws_it.save
      end
    end


    instance_types.each do |aws_it|
      AwsInstanceType.where(name: aws_it).first_or_create
    end

  end




  desc 'Create dependencies between AWS regions and instance types'
  task :create_aws_dependencies do

    # parse CSV
    csv = CSV.read('aws_regions.csv')
    regions = {}

    csv[0].each_with_index do |region,col|
      next if region.nil?

      regions[region] = []

      csv.each do |row|
        next if row[col] == region
        regions[region] << row[col]
      end

    end


    # create relations
    regions.each do |r|

      region_name = r[0]
      instance_types = r[1]

      region = AwsRegion.get_by_id_or_name(region_name)

      if region.nil?
        p "WARNING: NO SUCH REGION IN AWS_REGIONS TABLE: #{region_name}"
        next
      end


      instance_types.each do |aws_it|
        next if aws_it.nil?

        instance_type = AwsInstanceType.get_by_id_or_name(aws_it)

        if instance_type.nil?
          p "WARNING: NO SUCH INSTANCE TYPE IN AWS_INSTANCE_TYPES TABLE: #{aws_it}"
          next
        end

        record = AwsRegionInstanceType.where(aws_region: region, aws_instance_type: instance_type).first
        region.aws_region_instance_types.create(aws_instance_type: instance_type) unless record

      end

    end

  end


  desc 'test'
  task :test do

    #AwsRegionInstanceType.delete_all

    #region = AwsRegion.get_by_id_or_name('us-east-1')
    region = AwsRegion.get_by_id_or_name('ap-south-1')

    #region.aws_region_instance_types.each do |aw|
    #  p aw.inspect
    #  p '-------'
    #end

    p region.aws_region_instance_types.length

  end


  desc 'Add new AWS instance type. Pass regions as additional arguments!!'
  task :add_instance_type, [:name]  do |t, args|

    instance_type_name = args[:name]
    abort('Provide instance type name') if instance_type_name.nil?
    instance_type = AwsInstanceType.create(name: instance_type_name)

    args.extras.each do |region_name|
      region = AwsRegion.get_by_id_or_name(region_name)
      next if region.nil?

      res = AwsRegionInstanceType.create(aws_instance_type: instance_type, aws_region: region)
      if res.valid?
        puts "#{instance_type_name} added to region #{region.name}"
      else
        puts 'Something went wrong'
      end

    end

  end

  desc 'Add new AWS instance type to all regions'
  task :add_instance_type_to_all_regions, [:name] do |t, args|

    instance_type_name = args[:name]
    abort('Provide instance type name') if instance_type_name.nil?
    instance_type = AwsInstanceType.create(name: instance_type_name)

    if instance_type.valid?
      puts "#{instance_type_name} instance type added to DB"
    else
      puts 'Something went wrong'
    end

    regions = AwsRegion.all
    regions.each do |region|
      res = AwsRegionInstanceType.create(aws_instance_type: instance_type, aws_region: region)
      if res.valid?
        puts "#{instance_type_name} added to region #{region.name}"
      else
        puts 'Something went wrong'
      end
    end

  end


  desc 'Remove instance type from all regions'
  task :remove_instance_type_from_all_regions, [:name] do |t, args|

    instance_type_name = args[:name]
    abort('Provide instance type name') if instance_type_name.nil?
    intstance_type = AwsInstanceType.get_by_id_or_name(instance_type_name)
    abort('Instance type not found') if intstance_type.nil?

    relations = AwsRegionInstanceType.where(aws_instance_type: intstance_type)
    relations.delete_all
    puts 'Relations removed.'

    intstance_type.destroy
    puts 'Instance type removed.'

  end




=begin
  task :load_aws_data do

    file = File.read('aws_data.json')
    aws_data = JSON.parse(file)

    AwsRegion.delete_all
    AwsInstanceType.delete_all

    aws_data['aws_regions'].each do |k,v|
      AwsRegion.new(name:k,title:v).save
    end

    aws_data['aws_instance_types'].each do |name|
      AwsInstanceType.new(name: name).save
    end

  end
=end




end
