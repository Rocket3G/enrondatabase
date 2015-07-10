xml.instruct!
xml.gexf 'xmlns:viz' => 'http://www.gexf.net/1.1draft/viz', :xmlns => 'http://www.gexf.net/1.1draft', :version => '1.1' do
  xml.meta :lastmodifieddate => (Time.new).strftime("%Y-%m-%d") do |m|
    m.creator "Sander Verkuil"
    m.description "ENron Graph"
  end


  xml.graph :mode => "dynamic", defaultedgetype: "directed" do |graph|
    graph.nodes do |nodes|
      @users.each do |n|
        name = n.name
        nodes.node :id => n.mail, :label => name do |nn|
        end
      end
    end
    graph.edges do |edges|
      @edges.each do |e|
        edges.edge :id => "edge_#{e[:from]}_#{e[:to]}", :source => e[:from], :target => e[:to], :weight => e[:value]
      end
    end
  end
end
