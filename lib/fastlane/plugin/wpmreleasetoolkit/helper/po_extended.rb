require 'gettext/po'

## Extend GetText::PO to allow sorting by msgctxt
class PoExtended < GetText::PO
  def sort_by_msgctxt(entries)
    entries.sort_by do |msgid_entry|
      # msgid_entry = [[msgctxt, msgid], POEntry]
      msgid_entry[1][0]
    end
  end

  def sort(entries)
    case @order
    when :reference, :references # :references is deprecated.
      sort_by_reference(entries)
    when :msgid
      sort_by_msgid(entries)
    when :msgctxt
      sort_by_msgctxt(entries)
    else
      entries.to_a
    end
  end
end
