module LtiBridge
  class ContentItem
    def self.lti_resource_link(url:, title: nil, text: nil, icon: nil, thumbnail: nil, line_item: nil, custom: nil, iframe: nil, window: nil, available: nil, submission: nil)
      {
        type: "ltiResourceLink",
        title: title,
        url: url,
        text: text,
        icon: icon,
        thumbnail: thumbnail,
        lineItem: line_item,
        custom: custom,
        iframe: iframe,
        window: window,
        available: available,
        submission: submission
      }.compact
    end

    def self.link(url:, title: nil, icon: nil, thumbnail: nil, embed: nil, window: nil, iframe: nil)
      {
        type: "link",
        url: url,
        title: title,
        icon: icon,
        thumbnail: thumbnail,
        embed: embed,
        window: window,
        iframe: iframe
      }.compact
    end

    def self.html(html:)
      {
        type: "html",
        html: html
      }
    end

    def self.image(url:, metadata: nil)
      item = { type: "image", url: url }
      item["https://www.example.com/resourceMetadata"] = metadata if metadata
      item
    end

    def self.file(url:, title: nil, media_type:, expires_at: nil)
      {
        type: "file",
        title: title,
        url: url,
        mediaType: media_type,
        expiresAt: expires_at
      }.compact
    end

    def self.custom(type:, **attrs)
      { type: type }.merge(attrs)
    end
  end
end
