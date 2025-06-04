# app/controllers/concerns/pagination.rb
module Pagination
  extend ActiveSupport::Concern

  def paginate(scope)
    page = (params[:page] || 1).to_i
    per_page = [ (params[:per_page] || 25).to_i, 100 ].min # Max 100 per page

    offset = (page - 1) * per_page
    total_count = scope.count
    records = scope.limit(per_page).offset(offset)

    {
      records: records,
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil,
        next_page: page < (total_count.to_f / per_page).ceil ? page + 1 : nil,
        prev_page: page > 1 ? page - 1 : nil
      }
    }
  end
end
