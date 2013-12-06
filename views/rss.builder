url = request.url.chomp request.path_info

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Recall"
    xml.description "'cause you're too busy to remember"
    xml.link url

    @notes.each do |note|
      xml.item do
        xml.title h note.content
        xml.link "#{url}/#{note.id}"
        xml.guid "#{url}/#{note.id}"
        xml.pubDate Time.parse(note.created_at.to_s).rfc822
        xml.description h note.content
      end
    end
  end
end