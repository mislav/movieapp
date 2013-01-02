xml.OpenSearchDescription \
    'xmlns' => "http://a9.com/-/spec/opensearch/1.1/",
    'xmlns:moz' => "http://www.mozilla.org/2006/browser/search/" do
  xml.AdultContent false
  xml.InputEncoding 'UTF-8'
  xml.OutputEncoding 'UTF-8'

  xml.ShortName "movi.im"
  xml.Description "Search movi.im"
  xml.SearchForm "http://movi.im"
  xml.tag! 'moz:SearchForm', "http://movi.im"

  xml.Url type: 'text/html', rel: 'results', method: 'GET', template: 'http://movi.im' do
    xml.Param name: 'q', value: '{searchTerms}'
  end

  xml.Url type: "application/opensearchdescription+xml",
    rel: 'self', method: 'GET', template: request.url
end
