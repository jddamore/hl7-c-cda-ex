class Example < ActiveRecord::Base
  belongs_to :section

  has_many :approvals, dependent: :destroy

  validates :name, presence: true
  validates :section, presence: true
  validates :status, presence: true

  def self.query(search_params)
    the_arel = self.arel_table
    query = the_arel.project(the_arel[Arel.star])

    if search_params.present?
      filters = build_where(search_params)
      if filters
        Rails.logger.debug filters.to_sql
        query = query.where(filters)
      end
    end

    self.find_by_sql(query)
  end

  def self.build_where(search_params)
    the_arel = self.arel_table
    where_filter = nil

    unless search_params.search_text.blank?
      text_list = search_params.search_text.split.collect { |x| x.gsub(/'/, "'" => "''") }
      tsvector = Arel::Nodes::SqlLiteral.new("to_tsvector('english'," +
                                                 " name || ' ' || comments || ' ' || keywords || ' ' || custodian)")
      tsquery  = Arel::Nodes::SqlLiteral.new("to_tsquery('#{text_list.join(' | ')}')")
      where_filter = and_where(where_filter,
                               Arel::Nodes::InfixOperation.new('@@', tsvector, tsquery))
    end

    if search_params.section_ids && search_params.section_ids.count > 0
      where_filter = and_where(where_filter,
                               the_arel[:section_id].in(search_params.section_ids))
    end

    if search_params.status && search_params.status.count > 0
      where_filter = and_where(where_filter,
                               the_arel[:status].in(search_params.status))
    end

    if search_params.certification
      where_filter = and_where(where_filter, the_arel[:onc_certification].eq(true))
    end

    where_filter
  end

  def self.and_where(existing, new_filter)
    if existing
      existing.and(new_filter)
    else
      new_filter
    end
  end
end
