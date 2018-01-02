
require 'parser/current'
require 'unparser'

Parser::Builders::Default.emit_lambda = true
Parser::Builders::Default.emit_procarg0 = true

module HomebrewAutomation

  # An internal representation of some Formula.rb Ruby source file, containing
  # the definition of a Homebrew Bottle. See Homebrew docs for concepts:
  # https://docs.brew.sh/Bottles.html
  #
  # Instance methods produce new instances where applicable, leaving all
  # instances free from mutation.
  class Formula

    # A constructor method that parses the string form of a Homebrew Formula
    # source file into an internal representation
    #
    # @return [Formula]
    def self.parse_string s
      Formula.new (Parser::CurrentRuby.parse s)
    end

    # Take an post-parsing abstract syntax tree representation of a Homebrew Formula.
    # This is mostly not intended for common use-cases.
    #
    # @param ast [Parser::AST::Node]
    def initialize ast
      @ast = ast
    end

    # Produce Homebrew Formula source code as a string, suitable for saving as
    # a Ruby source file.
    #
    # @return [String]
    def to_s
      Unparser.unparse @ast
    end

    # Update a field in the Formula
    #
    # @param field [String] Name of the Formula field, e.g. `url`
    # @param value [String] Value of the Formula field, e.g. `https://github.com/easoncxz/homebrew-automation`
    # @return [Formula] a new instance of Formula with the changes applied
    def update_field field, value
      Formula.new update(
        @ast,
        [ by_type('begin'),
          by_both(
            by_type('send'),
            by_msg(field)),
          by_type('str')],
        -> (n) { n.updated(nil, [value]) })
    end

    # Insert or replace the Homebrew Bottle for a given OS
    #
    # @param os [String] Operating system name, e.g. "yosemite", as per Homebrew's conventions
    # @param sha256 [String] Checksum of the binary "Bottle" tarball
    # @return [Formula] a new instance of Formula with the changes applied
    def put_bottle os, sha256
      Formula.new update(
        @ast,
        bot_begin_path,
        put_bottle_version(os, sha256))
    end

    def == o
      self.class == o.class && self.ast == o.ast
    end

    alias :eql? :==

    protected
    attr_reader :ast

    private

    # Path to the :begin node
    # bot_begin_path :: [Choice]
    # type Choice = Proc (Node -> Bool)
    def bot_begin_path
      [ by_type('begin'),
        by_both(
          by_type('block'),
          by_child(
            by_both(
              by_type('send'),
              by_msg('bottle')))),
        by_type('begin')]
    end

    # Tricky: this is an insert-or-update
    # put_bottle_version :: String -> String -> Proc (Node -> Node)
    def put_bottle_version os, sha256
      -> (bot_begin) {
        bot_begin.updated(
          nil,  # keep the node type the unchanged
          bot_begin.children.reject(
            # Get rid of any existing matching ones
            &by_both(
              by_msg('sha256'),
              by_os(os))
          # Then add the one we want
          ).push(new_sha256(sha256, os)))
      }
    end

    # Build a new AST Node
    # String -> String -> Node
    def new_sha256 sha256, os
      # Unparser doesn't like Sexp, so let's bring
      # own own bit of "source code" inline.
      sha256_send = Parser::CurrentRuby.parse(
        'sha256 "checksum-here" => :some_os')
      with_sha256 = update(
        sha256_send,
        [ by_type('hash'),
          by_type('pair'),
          by_type('str') ],
        -> (n) { n.updated(nil, [sha256]) })
      with_sha256_and_os = update(
        with_sha256,
        [ by_type('hash'),
          by_type('pair'),
          by_type('sym') ],
        -> (n) { n.updated(nil, [os.to_sym]) })
      with_sha256_and_os
    end

    # update :: Node -> [Choice] -> Proc (Node -> Node) -> Node
    def update node, path, fn
      if path.length == 0 then
        fn.(node)
      else
        choose, *rest = path
        node.updated(
          nil,    # Don't change node type
          node.children.map do |c|
            choose.(c) ? update(c, rest, fn) : c
          end)
      end
    end

    # zoom_in :: Node -> [Choice] -> Node
    def zoom_in node, path
      if path.length == 0 then
        node
      else
        choose, *rest = path
        chosen = node.children.select(&choose).first
        zoom_in chosen, rest
      end
    end

    # by_both
    #   :: Proc (Node -> Bool)
    #   -> Proc (Node -> Bool)
    #   -> Proc (Node -> Bool)
    def by_both p, q
      -> (n) { p.(n) && q.(n) }
    end

    # by_msg :: String -> Proc (Node -> Bool)
    def by_msg msg
      -> (n) { n.children[1] == msg.to_sym }
    end

    # by_type :: String -> Proc (Node -> Bool)
    def by_type type
      -> (n) {
        n &&
        n.is_a?(AST::Node) &&
        n.type == type.to_sym
      }
    end

    # Matches if one of the node's children matches the given p
    # by_child :: Proc (Node -> Bool) -> Proc (Node -> Bool)
    def by_child p
      -> (n) {
        n &&
        n.is_a?(AST::Node) &&
        n.children.select(&p).size > 0
      }
    end

    # Matches if this :send node expresses the give sha256 sum
    # by_os :: String -> Proc (Node -> Bool)
    def by_os os
      -> (n) {
        zoom_in(n, [
          by_type('hash'),
          by_type('pair'),
          by_type('sym')])
        .children[0] == os.to_sym
      }
    end

  end

end
