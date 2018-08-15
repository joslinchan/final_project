class Api::V1::InspirationsController < Api::ApplicationController
  before_action :authenticate_user!

  def index
    user = current_user
    inspirations = user.inspirations.order(created_at: :desc)
    render( 
      json: inspirations, 
      each_serializer: InspirationSerializer
      )
  end

  def create
    inspiration = Inspiration.new inspiration_params
    inspiration.user = current_user
    
    if inspiration.save
      if params[:hex].is_a?(Array)
        params[:hex].each do |hex|
          new_hex = Hex.new(code: hex)
          new_hex.inspiration = inspiration
          new_hex.save
        end
      else
       new_hex = Hex.new(code: params[:hex])
        new_hex.inspiration = inspiration
        new_hex.save
      end
      render(
        json: {
          id: inspiration.id,
          message: "Inspiration created"
        }
      )
    else
      render(
        json: {errors: inspiration.errors},
        status: 422
      )
    end
  end

  def destroy
    inspiration.destroy
    render(
      status: 200,
      json: {
        status: 200,
        message: "Inspiration destroyed"}
    )
  end

  def search
    paletteCollection = SearchApi.new.search_palettes params[:query]
    colourCollection = SearchApi.new.search_colours params[:query]
    patternCollection = SearchApi.new.search_patterns params[:query]

    if params[:query]
      photos = UnsplashRetriever.new.get_photos params[:query]
    else
      photos = UnsplashRetriever.new.get_random
    end
    
    everything = paletteCollection + colourCollection + patternCollection + photos

    respond_to do |format|
      format.json { render json: everything }
    end
  end

  private
  def inspiration
    inspiration ||= Inspiration.find params[:id]
  end

  def inspiration_params
    params.require(:inspiration).permit(:title, :image_url, :url, :hex)
  end 

end
