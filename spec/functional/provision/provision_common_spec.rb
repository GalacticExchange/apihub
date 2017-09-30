RSpec.describe "Provision::Service.run", :type => :request do
  before :each do

  end

  it 'if success' do
    cmd = Gexcore::Provision::Service.build_cmd_cap(
        'provision:test_task',
        " "
    )

    res = Gexcore::Provision::Service.run("test_task", cmd)

    expect(res.success?).to eq true
  end


  it 'if error in cap script' do
    cmd = Gexcore::Provision::Service.build_cmd_cap(
        'provision:test_task_fail',
        " "
    )

    res = Gexcore::Provision::Service.run("test_task_fail", cmd)

    expect(res.error?).to eq true
  end

end

