class ItemsController < ApplicationController
  # before_action :search_item

  def index
    @q = Item.ransack(params[:q])
    @items = if params[:q].present?
               @q.result(distinct: true).where(stock: 0).order('created_at DESC')
             else
               Item.where(stock: 0).order('created_at DESC')
             end
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.create(item_params)
    if @item.save
      redirect_to items_path, notice: '商品を出品しました。'
    else
      flash[:alert] = '入力情報が間違っています。'
      render :new
    end
  end

  def show
    @item = Item.find(params[:id])
    @count = if @item.tickets.count.positive?
               @item.quantity - @item.tickets.count
             else
               @item.quantity
             end
    @count = '完売しました' unless @count.positive?
    @tickets = Ticket.where(item_id: params[:id])
    @favorite = Favorite.find_by(item_id: params[:item_id]) if @item.favorites.present?
  end

  def edit
    set_item
  end

  def update
    set_item
    if @item.update(item_params)
      redirect_to item_path(@item), notice: '商品情報を変更しました。'
    else
      flash[:alert] = '商品情報が間違っています。'
      render :edit
    end
  end

  def destroy
    set_item
    if @item.destroy
      redirect_to items_path, notice: '商品を削除しました。'
    else
      flash[:alert] = '商品削除に失敗しました。'
      render :show
    end
  end

  def favorites
    @favorites = current_user.favorite_items.includes(:user).recent
  end

  def stock
    @items = Item.where(user_id: current_user, stock: 1).order('created_at DESC')
  end

  def stock_out
    @item = Item.find(params[:item_id])
    @item.stock = 0
    if @item.save
      redirect_to items_path, notice: 'ストックから商品を出品しました。'
    else
      flash[:alert] = 'ストック商品の出品に失敗しました。'
      render :stock
    end
  end

  def receipt
    @receipt_items = Item.where(user_id: current_user, stock: false)
    @used_tickets = Ticket.where(receipt: 1, item_id: current_user.items)
  end

  def urgent
    @item = Item.where(user_id: current_user).last
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(
      :name,
      :quantity,
      :description,
      :category_id,
      :condition_id,
      :deadline,
      :prefecture_id,
      :price,
      :contact_location,
      :image,
      :stock,
      :limit
    ).merge(user_id: current_user.id)
  end

  def search_item
    @p = Item.ransack(params[:q]) # 検索オブジェクトを生成
  end

  def set_item_column
    @item_name = Item.select('name').distinct  # 重複なくnameカラムのデータを取り出す
  end
end
