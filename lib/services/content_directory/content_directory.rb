require 'builder'
require 'json'

module BrowseHelper
  def browse_children(id, filter)
    if id == '0'
      path = '/home/patrik'
    else
      path = id
    end
    
    subfolders = Dir["#{path}/*"].reject {|d|
      not File.directory?(d)
    }.map {|d|
      { id: d,
        parent_id: id == '/home/patrik' ? '0' : id,
        child_count: Dir["#{d}/*"].count,
        title: File.basename(d),
        klass: "object.container.storageFolder" }
    }

    files = Dir["#{path}/*.mkv"].select { |d| 
      `avprobe -show_format -of json #{d} 2> /dev/null`; $?.to_i == 0 
    }.map { |d| 
      json =`avprobe -show_format -of json #{d} 2> /dev/null`
      data = JSON.parse(json)
      { id: d,
        parent_id: id == '/home/patrik' ? '0' : id,
        title:  data['format']['tags']['title'],
        filename: data['format']['filename'],
        size: data['format']['size'].to_i }
    }

    
    xml = Builder::XmlMarkup.new 
      xml.tag! 'DIDL-Lite',  'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                           'xmlns:upnp' => "urn:schemas-upnp-org:metadata-1-0/upnp/",
                           'xmlns' => "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
                           'xmlns:dlna' => "urn:schemas-dlna-org:metadata-1-0/" do
        subfolders.each do |folder|
          xml.tag! 'container', id: folder[:id],
                             parentID: folder[:parent_id],
                             restricted: 1,
                             searchable: 1,
                             childCount: folder[:child_count] do
            xml.tag! 'dc:title', folder[:title]
            xml.tag! 'upnp:class', folder[:klass]
            xml.tag! 'upnp:storageUsed', "-1"
          end
        end
      files.each do |file|
        xml.tag! 'item', id: file[:id],
                         parentID: file[:parent_id],
                         restricted: 1 do
          xml.tag! 'dc:title', file[:title]
          xml.tag! 'upnp:class', 'object.item.videoItem'
          xml.tag! 'res', "#{request.base_url}/ContentDirectory#{file[:id]}",
            size: file[:size], 
            protocolInfo: 'http-get:*:video/x-matroska:*'
        end
      end
    end
    [xml.target!, subfolders.size + files.size]
  end

  def browse_metadata(id, filter)
    if id == '0'
      path = '/home/patrik' 
    else
      path = id
    end

    subfolders = Dir["#{path}/*"].reject {|d|
      not File.directory?(d) }

    folder = {
      id: id,
      parent_id: path == '/home/patrik' ? '-1' : File.dirname(path),
      title: 'root',
      child_count: subfolders.size
    }

    xml = Builder::XmlMarkup.new
    xml.tag! 'DIDL-Lite',  'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                           'xmlns:upnp' => "urn:schemas-upnp-org:metadata-1-0/upnp/",
                           'xmlns' => "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
                           'xmlns:dlna' => "urn:schemas-dlna-org:metadata-1-0/" do
        xml.tag! 'container', id: folder[:id],
                           parentID: folder[:parent_id],
                           restricted: 1,
                           searchable: 1,
                           childCount: folder[:child_count] do
          xml.tag! 'upnp:searchClass', "object.item.videoItem", includeDerived: 1
          xml.tag! 'upnp:searchClass', "object.item.imageItem", includeDerived: 1
          xml.tag! 'upnp:searchClass', "object.item.audioItem", includeDerived: 1
          xml.tag! 'dc:title', folder[:title]
          xml.tag! 'upnp:class', 'object.container.storageFolder'
          xml.tag! 'upnp:storageUsed', "-1"

      end
    end
    [xml.target!, 1]
  end
end


class ContentDirectory < Service
  configure do
    set :threaded, false
  end
  
  register Sinatra::UpnpSoap
  helpers BrowseHelper

  get '/' do
    content_type 'application/xml'
    puts "Reading contentdir"
    File.read(File.join(settings.views, "ContentDir.xml"))
  end

  get %r{(/.+)$} do
    puts "Streaming #{params[:captures].first}"
    #puts JSON.pretty_generate(env)
    if request.env['HTTP_RANGE'] != nil
        byte_start,byte_stop = request.env['HTTP_RANGE'].match(/bytes=(\d*)-(\d*)/)[1..2].map(&:to_i)
    else
      byte_start, byte_stop = 0, 0
    end

    if byte_stop == 0
      byte_stop = File.size(params[:captures].first)
    end
    if byte_start != 0
      status 206
    end
    puts request.env['HTTP_RANGE'] 
    puts "Streaming #{byte_start}-#{byte_stop}"

    headers['Content-Type'] = 'video/x-matroska'
    headers['Accept-Ranges'] = 'bytes'
    headers['Conent-Range'] = "bytes #{byte_start}-#{byte_stop}/#{File.size(params[:captures].first)}"
    headers['Content-Length'] = File.size(params[:captures].first).to_s
    stream(:keep_alive) do |out|
      streaming = true
      out.callback { streaming = false }
      out.errback { streaming = false }
      file = File.open(params[:captures].first, 'r')
      file.seek(byte_start)
      writer = lambda do
        if streaming && !out.closed?
          buff = file.read(2*1024)
        else
          puts "Stop stream"
          file.close
          next
        end

        unless buff == nil
          body << buff
          EventMachine.next_tick &writer
        else
          puts "Stream done"
          file.close
        end
      end
      writer.call
    end
  end

  upnp :Browse do |params|
    puts "Request\n#{params}\n\n"
    if params[:BrowseFlag] == 'BrowseMetadata'
      browse_xml,n = browse_metadata(params[:ObjectID], params[:Filter])
    else
      browse_xml,n = browse_children(params[:ObjectID], params[:Filter])
    end
    { Result: browse_xml, 
      NumberReturned: n,
      TotalMatches: n,
      UpdateId: 0 }  
  end
end

