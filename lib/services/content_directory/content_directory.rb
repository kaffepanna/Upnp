require 'builder'
require 'json'
require_relative '../../common/files'

module BrowseHelper
  def get_container(xml, child)
    xml.tag! 'container', id: child.id,
                             parentID: child.parent_id,
                             restricted: 1 do
      xml.tag! 'dc:title', child.filename
      xml.tag! 'dc:date', child.mtime
      xml.tag! 'upnp:class', 'object.container'
    end
  end

  def get_file(xml, child)
    xml.tag! 'item', id: child.id,
              parentID: child.parent_id,
              restricted: 1 do
      xml.tag! 'dc:title', child.title
      xml.tag! 'upnp:class', 'object.item.videoItem'
      #xml.tag! 'res', "#{request.base_url}/ContentDirectory#{file[:id]}",
      #          size: file[:size],
      #  protocolInfo: 'http-get:*:video/x-matroska:*'
      end
  end

  def get_metadata(xml, child)

  end

  def browse_children(id, filter, start, stop)
    children = Metadata.get_children id: id, base_path: '/home/epetpat'
    #children = children[start..[(start + stop), children.size].min]
    xml = Builder::XmlMarkup.new
      xml.tag! 'DIDL-Lite',  'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                           'xmlns:upnp' => "urn:schemas-upnp-org:metadata-1-0/upnp/",
                           'xmlns' => "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
                           'xmlns:dlna' => "urn:schemas-dlna-org:metadata-1-0/" do
        children.each do |child|
          case child
          when DirectoryMetadata then get_container(xml, child)
          when VideoMetadata then get_file(xml, child)
          end
        end
    end
    [xml.target!, children.size]
  end

  def browse_metadata(id, filter)
    file = Metadata.get_metadata(id: id, base_path: '/home/epetpat')

    headers["EXT"] = ""
    xml = Builder::XmlMarkup.new
    xml.tag! 'DIDL-Lite',  'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                           'xmlns:upnp' => "urn:schemas-upnp-org:metadata-1-0/upnp/",
                           'xmlns' => "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
                           'xmlns:dlna' => "urn:schemas-dlna-org:metadata-1-0/" do
        xml.tag! 'container', id: file.id,
                           parentID: file.parent_id,
                           restricted: 1,
                           searchable: 1,
                           childCount: file.child_count do
          # xml.tag! 'upnp:searchClass', "object.item.videoItem", includeDerived: 1
          # xml.tag! 'upnp:searchClass', "object.item.imageItem", includeDerived: 1
          # xml.tag! 'upnp:searchClass', "object.item.audioItem", includeDerived: 1
          xml.tag! 'dc:title', file.filename
          xml.tag! 'upnp:class', 'object.container'
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
    start = params[:StartingIndex].to_i
    len = params[:RequestCount].to_i
    if params[:BrowseFlag] == 'BrowseMetadata'
      browse_xml,n = browse_metadata(params[:ObjectID], params[:Filter])
    else
      browse_xml,n = browse_children(params[:ObjectID], params[:Filter], start, len)
    end
      puts browse_xml
    { Result: "#{browse_xml}\n",
      NumberReturned: n,
      TotalMatches: n,
      UpdateId: (rand * 100).to_i }
  end
end

