# frozen_string_literal: true

require 'sequel/force-hooks'

module Sequel
  module ForceHooks
    private

    def add_transaction_hook(conn, type, block)
      stacked_hooks = _trans(conn)[:stacked_hooks]

      if stacked_hooks.empty?
        super
      else
        hooks = stacked_hooks.last[type] ||= []
        hooks << block
      end
    end

    def add_savepoint_hook(conn, type, block)
      if _trans(conn)[:force_hooks].last && in_savepoint?(conn)
        hooks = _trans(conn)[:stacked_hooks].last[type] ||= []
        hooks << block
      else
        super
      end
    end

    def transaction_hooks(conn, committed)
      if _trans(conn)[:force_hooks].last && in_savepoint?(conn)
        _trans(conn)[:stacked_hooks].last[committed ? :after_commit : :after_rollback]
      else
        super
      end
    end

    def transaction_options(conn, opts)
      hash = super

      if t = _trans(conn)
        if !opts.key?(:force_hooks) && t[:force_hooks].last == :nested
          opts[:force_hooks] = true
        end

        t[:force_hooks].push(opts[:force_hooks])
        t[:stacked_hooks].push({}) if opts[:force_hooks]
      else
        hash[:force_hooks] = [opts[:force_hooks]]
        hash[:stacked_hooks] = []
      end

      hash
    end

    def transaction_finished?(conn)
      _trans(conn)[:stacked_hooks].pop if _trans(conn)[:force_hooks].last
      _trans(conn)[:force_hooks].pop
      super
    end
  end

  Database.register_extension(:force_hooks) { |db| db.extend(Sequel::ForceHooks) }
end
