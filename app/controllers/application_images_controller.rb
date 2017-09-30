=begin
class ApplicationImagesController < ApplicationController
  before_action :set_application_image, only: [:show, :edit, :update, :destroy]

  # GET /application_images
  # GET /application_images.json
  def index
    @application_images = ApplicationImage.all
  end

  # GET /application_images/1
  # GET /application_images/1.json
  def show
  end

  # GET /application_images/new
  def new
    @application_image = ApplicationImage.new
  end

  # GET /application_images/1/edit
  def edit
  end

  # POST /application_images
  # POST /application_images.json
  def create
    @application_image = ApplicationImage.new(application_image_params)

    respond_to do |format|
      if @application_image.save
        format.html { redirect_to @application_image, notice: 'Application image was successfully created.' }
        format.json { render :show, status: :created, location: @application_image }
      else
        format.html { render :new }
        format.json { render json: @application_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /application_images/1
  # PATCH/PUT /application_images/1.json
  def update
    respond_to do |format|
      if @application_image.update(application_image_params)
        format.html { redirect_to @application_image.library_application, notice: 'Application image was successfully updated.' }
      end
    end
  end

  # DELETE /application_images/1
  # DELETE /application_images/1.json
  def destroy
    @application_image.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Application image was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_application_image
      @application_image = ApplicationImage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def application_image_params
      params.require(:application_image).permit(:library_application__id, :avatar)
    end
end
=end