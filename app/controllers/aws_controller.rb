class AwsController < AccountBaseController


  def instance_types

    with_hadoop = to_boolean(params[:withHadoop])

    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )

    aws_region_id = @current_cluster.get_option('aws_region_id')
    region = AwsRegion.get_by_id_or_name(aws_region_id)

    # todo: check if region nil

    ec2_types = region.aws_instance_types.w_not_deprecated #.order(name: :asc)

    if with_hadoop
      ec2_types = ec2_types.for_hadoop
    end

    ec2_types = ec2_types.map(&:to_hash) if ec2_types

    res = Gexcore::Response.res_data({result: ec2_types})

    respond_to do |format|
      format.html { raise 'not supported'  }
      format.json{ return_json(res) }
    end
  end


end
