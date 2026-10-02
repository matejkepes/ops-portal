class Issues::DraftsController < ApplicationController
  before_action :require_full_access_user
  before_action :ensure_user_onboarded
  before_action :check_rate_limit, only: [ :new, :new_question, :create ]
  before_action :load_draft, except: [ :new, :new_question, :create, :thanks ]

  def new
    @previous_draft = current_user.current_draft
    @draft = Issues::Draft.new(issue_type: :issue)
  end

  def new_question
    @draft = Issues::Draft.new(issue_type: :question)
    render :new
  end

  def edit
    @draft.valid?(:photos_step)
    render :new
  end

  def create
    @draft = Issues::Draft.new(draft_params)
    @draft.author = current_user
    if @draft.save(context: :photos_step)
      ::Issues::Draft::GenerateSuggestionsJob.perform_later(@draft)
      redirect_to issues_draft_geo_path(@draft)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @draft.photos = @draft.photos.blobs + Array(draft_params[:photos])
    if @draft.save(context: :photos_step)
      redirect_to edit_issues_draft_path(@draft, next: params[:next])
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy_photo
    @draft.photos.find(params[:photo_id]).purge_later
    redirect_to edit_issues_draft_path(@draft, next: params[:next])
  end

  def rotate_photo
    blob = @draft.photos.find(params[:photo_id]).blob
    blob.update!(rotation: (blob.rotation - 90) % 360)
    redirect_to edit_issues_draft_path(@draft, next: params[:next])
  end

  def duplicates
    @draft.update(duplicates_shown: true)

    redirect_to issues_path(pin: "#{@draft.latitude},#{@draft.longitude}", kategoria: @draft.category&.name, podkategoria: @draft.subcategory&.name, typ: @draft.subtype&.name)
  end

  def thanks
  end

  private

  def check_rate_limit
    redirect_to please_wait_profile_path if current_user.create_issue_limit_exceeded?
  end

  def draft_params
    params.expect(issues_draft: [ :issue_type, { photos: [] } ])
  end

  def load_draft
    @draft = current_user.issues_drafts.find(params[:id] || params[:draft_id])
  end
end
