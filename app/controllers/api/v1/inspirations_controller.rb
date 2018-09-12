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
    inspiration = Inspiration.new(
      title: params[:title],
      image_url: params[:image_url],
      url: params[:url]
    )
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
        status: 200,
        json: inspiration 
      )
    else
      render(
        status: 422,
        json: {errors: inspiration.errors}
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
    fetch_design_assets

    if (@everything==0)
      return null_result
    else

      @everything.each do |thing|
        if (thing["hex"])
          thing['save_link'] = api_v1_inspirations_path(title: thing["title"], image_url: URI.encode(thing["imageUrl"]), url: URI.encode(thing["url"]), hex: thing["hex"])
        elsif (thing["colors"])
          thing['save_link'] = api_v1_inspirations_path(title: thing["title"], image_url: URI.encode(thing["imageUrl"]), url: URI.encode(thing["url"]), hex: thing["colors"]["hex"])
        else
          thing['save_link'] = api_v1_inspirations_path(title: "Untitled", image_url: URI.encode(thing["urls"]["thumb"]), url: URI.encode(thing["links"]["html"]), hex: thing["color"])
        end
      end
      
    end

    respond_to do |format|
      format.json { render json: @everything }
    end
  end

  private
  def inspiration
    inspiration ||= Inspiration.find params[:id]
  end

  def inspiration_params
    params.permit(:title, :image_url, :url, :hex)
  end 

  def fetch_design_assets
    colourCollection = ColourLoversApiParser.parse_colours params[:query]
    paletteCollection = ColourLoversApiParser.parse_palettes params[:query]
    patternCollection = ColourLoversApiParser.parse_patterns params[:query]

    paletteCollection ||= 0
    colourCollection ||= 0
    patternCollection ||= 0
    
    if params[:query]
      photos = UnsplashApiRetriever.new.get_photos params[:query]
    else
      photos = UnsplashApiRetriever.new.get_random
    end 

    if (paletteCollection==0)
      @everything = paletteCollection + colourCollection + patternCollection
    else
      @everything = paletteCollection + colourCollection + patternCollection + photos
    end
  end

  def null_result
    render(
      status: 404,
      json: {
        status: 404,
        errors: [{
          type: "NotFound"
        }]
      }
    )
  end

end

=begin     
everything = paletteCollection + colourCollection + patternCollection 
=end
