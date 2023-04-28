# require "openssl"
# 
# key = OpenSSL::PKey::RSA.new 4096
# 
# name = OpenSSL::X509::Name.parse '/CN=nobody'
# 
# cert = OpenSSL::X509::Certificate.new
# 
# cert.version = 2
# 
# cert.serial = 0
# 
# cert.not_before = Time.now
# 
# cert.not_after = Time.now + 606024364.251
# 
# cert.publickey = key.publickey

# cert.subject = name
# 
# cert.issuer = name
# 
# cert.sign key, OpenSSL::Digest.new('SHA256')
# 
# open 'certificate.pem', 'w' do |io| io.write cert.to_pem end
# 
# open 'privatekey.pem', 'w' do |io| io.write key.to_pem end


require 'rubygems'
require 'openssl'

key = OpenSSL::PKey::RSA.new(1024)
public_key = key.public_key

subject = "/C=BE/O=Test/OU=Test/CN=Test"

cert = OpenSSL::X509::Certificate.new
cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
cert.not_before = Time.now
cert.not_after = Time.now + 365 * 24 * 60 * 60
cert.public_key = public_key
cert.serial = 0x0
cert.version = 2

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = cert
ef.issuer_certificate = cert
cert.extensions = [
  ef.create_extension("basicConstraints","CA:TRUE", true),
  ef.create_extension("subjectKeyIdentifier", "hash"),
  # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
]
cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                       "keyid:always,issuer:always")

cert.sign key, OpenSSL::Digest::SHA1.new
puts key
puts "---------------"
puts cert.to_pem
