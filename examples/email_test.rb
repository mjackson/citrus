# This file contains a suite of tests for the EmailAddress grammar
# found in email.citrus.

require 'citrus'
Citrus.require File.expand_path('../email', __FILE__)
require 'test/unit'

class EmailAddressTest < Test::Unit::TestCase
  def test_addr_spec_valid
    addresses = %w[
      l3tt3rsAndNumb3rs@domain.com
      has-dash@domain.com
      hasApostrophe.o'leary@domain.org
      uncommonTLD@domain.museum
      uncommonTLD@domain.travel
      uncommonTLD@domain.mobi
      countryCodeTLD@domain.uk
      countryCodeTLD@domain.rw
      lettersInDomain@911.com
      underscore_inLocal@domain.net
      IPInsteadOfDomain@127.0.0.1
      subdomain@sub.domain.com
      local@dash-inDomain.com
      dot.inLocal@foo.com
      a@singleLetterLocal.org
      singleLetterDomain@x.org
      &*=?^+{}'~@validCharsInLocal.net
      foor@bar.newTLD
    ]

    addresses.each do |address|
      match = EmailAddress.parse(address)
      assert(match)
      assert_equal(address, match)
    end
  end

  # NO-WS-CTL       =       %d1-8 /         ; US-ASCII control characters
  #                         %d11 /          ;  that do not include the
  #                         %d12 /          ;  carriage return, line feed,
  #                         %d14-31 /       ;  and white space characters
  #                         %d127
  def test_no_ws_ctl
    chars = chars_no_ws_ctl

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :'NO-WS-CTL')
      assert(match)
      assert_equal(c, match)
    end
  end

  # quoted-pair     =       ("\" text) / obs-qp
  def test_quoted_pair
    chars = chars_quoted_pair

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :'quoted-pair')
      assert(match)
      assert_equal(c, match)
    end
  end

  # atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
  #                     "!" / "#" /        ;  characters not including
  #                     "$" / "%" /        ;  specials.  Used for atoms.
  #                     "&" / "'" /
  #                     "*" / "+" /
  #                     "-" / "/" /
  #                     "=" / "?" /
  #                     "^" / "_" /
  #                     "`" / "{" /
  #                     "|" / "}" /
  #                     "~"
  def test_atext
    chars  = ('A'..'Z').to_a
    chars += ('a'..'z').to_a
    chars += ('0'..'9').to_a
    chars.push(*%w[! # $ % & ' * + - / = ? ^ _ ` { | } ~])

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :atext)
      assert(match)
      assert_equal(c, match)
    end
  end

  # qtext           =   %d33 /             ; Printable US-ASCII
  #                     %d35-91 /          ;  characters not including
  #                     %d93-126 /         ;  "\" or the quote character
  #                     obs-qtext
  def test_qtext
    chars  = ["\x21"]
    chars += ("\x23".."\x5B").to_a
    chars += ("\x5D".."\x7E").to_a

    # obs-qtext
    chars += chars_obs_no_ws_ctl

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :qtext)
      assert(match)
      assert_equal(c, match)
    end
  end

  # dtext           =   %d33-90 /          ; Printable US-ASCII
  #                     %d94-126 /         ;  characters not including
  #                     obs-dtext          ;  "[", "]", or "\"
  def test_dtext
    chars  = ("\x21".."\x5A").to_a
    chars += ("\x5E".."\x7E").to_a

    # obs-dtext
    chars += chars_obs_no_ws_ctl
    chars += chars_quoted_pair

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :dtext)
      assert(match)
      assert_equal(c, match)
    end
  end

  # text            =   %d1-9 /            ; Characters excluding CR
  #                     %d11 /             ;  and LF
  #                     %d12 /
  #                     %d14-127
  def test_text
    chars = chars_text

    chars.each do |c|
      match = EmailAddress.parse(c, :root => :text)
      assert(match)
      assert_equal(c, match)
    end
  end

  # [\x01-\x08\x0B\x0C\x0E-\x1F\x7F]
  def chars_no_ws_ctl
    chars  = ("\x01".."\x08").to_a
    chars << "\x0B"
    chars << "\x0C"
    chars += ("\x0E".."\x1F").to_a
    chars << "\x7F"
    chars
  end

  # [\x01-\x09\x0B\x0C\x0E-\x7F]
  def chars_text
    chars  = ("\x01".."\x09").to_a
    chars << "\x0B"
    chars << "\x0C"
    chars += ("\x0E".."\x7F").to_a
    chars
  end

  # [\x01-\x08\x0B\x0C\x0E-\x1F\x7F]
  def chars_obs_no_ws_ctl
    chars_no_ws_ctl
  end

  # ("\\" text) | obs-qp
  def chars_quoted_pair
    chars  = chars_text.map {|c| "\\" + c }
    chars += chars_obs_qp
    chars
  end

  # "\\" ("\x00" | obs-NO-WS-CTL | "\n" | "\r")
  def chars_obs_qp
    chars  = ["\x00"]
    chars += chars_obs_no_ws_ctl
    chars << "\n"
    chars << "\r"
    chars.map {|c| "\\" + c }
  end
end
