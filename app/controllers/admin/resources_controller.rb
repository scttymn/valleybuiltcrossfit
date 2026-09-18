module Admin
  # Generic CRUD for the simple content models. Subclasses describe their
  # model and fields; the shared views in admin/resources render everything.
  class ResourcesController < BaseController
    Field = Data.define(:name, :type, :hint, :options) do
      def self.[](name, type = :string, hint: nil, options: nil) = new(name:, type:, hint:, options:)
      def label = name.to_s.humanize
    end

    class_attribute :model, :fields, :columns, :title, :sortable, default: nil

    helper_method :model, :fields, :columns, :title, :record_path, :records_path

    before_action :set_record, only: %i[edit update destroy]

    def index
      @records = sortable ? model.ordered : model.order(date: :desc)
      render "admin/resources/index"
    end

    def new
      @record = model.new
      render "admin/resources/new"
    end

    def create
      @record = model.new(record_params)
      if @record.save
        redirect_to records_path, notice: "#{title.singularize} created."
      else
        render "admin/resources/new", status: :unprocessable_entity
      end
    end

    def edit
      render "admin/resources/edit"
    end

    def update
      if @record.update(record_params)
        redirect_to records_path, notice: "#{title.singularize} saved."
      else
        render "admin/resources/edit", status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy!
      redirect_to records_path, notice: "#{title.singularize} deleted.", status: :see_other
    end

    private

    def set_record
      @record = model.find(params[:id])
    end

    def record_params
      permitted = fields.map(&:name)
      attrs = params.expect(param_key => permitted)
      fields.select { _1.type == :file }.each do |field|
        attrs.delete(field.name) if attrs[field.name].blank?
        @record&.public_send(field.name)&.purge_later if params.dig(param_key, "remove_#{field.name}") == "1"
      end
      attrs
    end

    def param_key = model.model_name.param_key.to_sym
    def records_path = url_for(controller: controller_path, action: :index)
    def record_path(record) = url_for(controller: controller_path, action: :update, id: record)
  end
end
