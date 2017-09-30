module Gexcore::Clusters::Aws
  class Service < Gexcore::BaseService

    def self.validate_create_cluster_data(user,options)
      res = Response.new

      # region
      if options[:aws_region_id].nil?
        res.set_error("cluster_invalid", "AWS region not set", "aws region not set")
        return res
      end


      # set name instead of id
      aws_region = (AwsRegion.get_by_id_or_name(options[:aws_region_id]) rescue nil)

      if aws_region.nil?
        res.set_error("cluster_invalid", "AWS region not set", "aws region not set")
        return res
      end

      options[:aws_region] = aws_region.name

      # aws connection
      res_aws_connection = aws_check_connection(options)

      if !res_aws_connection
        return res.set_error("cluster_invalid", "Wrong AWS credentials")
      end

      # vpc limit
      res_vpc_limit = aws_check_vpc_limit(options)

      if !res_vpc_limit
        return res.set_error("cluster_invalid", "VPC limit in this AWS region is exceeded. Select another AWS region or remove cluster(s) in this region.")
      end


      res.set_data
    end

    def self.fog_connection(options)
      Fog::Compute.new(
          :provider => 'AWS',
          :region => options[:aws_region],
          :aws_access_key_id => options[:aws_key_id],
          :aws_secret_access_key => options[:aws_secret_key]
      )

    end

    def self.aws_check_connection(options)
      # check connection to AWS
      require 'fog'
      #require 'aws-sdk'

      begin
        fog = fog_connection(options)
        vpc_arr = fog.describe_vpcs.body['vpcSet']

=begin
        # with aws
        aws = Aws::EC2::Client.new(
            access_key_id: options[:aws_key_id],
            secret_access_key: options[:aws_secret_key],
            region: options[:aws_region]
        )


        aws.create_vpc({
             dry_run: true,
             cidr_block: '10.177.0.0/16', # required
             instance_tenancy: "default", # accepts default, dedicated, host
             amazon_provided_ipv_6_cidr_block: false
                       })

        raise_error('Request would have succeeded, but DryRun flag is set.')
=end


        return true
      rescue => e
        gex_logger.error("aws_check_connection", "Cannot connect to AWS with keys", {exception: e.message})
        return false
      end

      true
    end

    def self.aws_check_vpc_limit(options={})
      require 'fog'

      begin
        fog = fog_connection(options)

        vpc_arr = fog.describe_vpcs.body['vpcSet']
        vpc_amount = vpc_arr.length

        return vpc_amount < 5
      rescue => e
        gex_logger.error("aws_check_vpc_limit", "error checking VPC", {exception: e.message})
        return false
      end

      true
    end

  end
end

