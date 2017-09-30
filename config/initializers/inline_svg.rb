class NgIfCustomTransform < InlineSvg::CustomTransformation
  def transform(doc)
    doc = Nokogiri::XML::Document.parse(doc.to_html)
    svg = doc.at_css 'svg'
    svg['ng-if'] = value
    doc
  end
end

InlineSvg.configure do |config|
  config.add_custom_transformation(attribute: :ng_if, transform: NgIfCustomTransform)
end
