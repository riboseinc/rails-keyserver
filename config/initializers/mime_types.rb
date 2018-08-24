# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
#

# XXX: load order problems:
# extension = :"#{RK::Key::PGP.extension}"
extension = :asc
Mime::Type.register "application/pgp-keys", extension

ActionController::Renderers.add extension do |object, options|
  return head 404 if object.nil?

  send_data(
    # object.public.unpack('m').first,
    object.public,
    # type:        'application/pgp-keys; charset=utf-8; header=present',
    type:        Mime[extension],
    disposition: "attachment; filename=#{options[:filename] ||
      object.fingerprint}.#{extension}",
  )
end
