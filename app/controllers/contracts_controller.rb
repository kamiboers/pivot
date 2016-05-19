class ContractsController < ApplicationController

  def new
    if current_user
      cart = session[:cart].transform_keys { |k| k.to_sym }
      @loan_requests = cart[:requests].map { |lr| LoanRequest.find(lr) }
      @loan_offers = cart[:offers].map { |lo| LoanOffer.find(lo) }
    else
      render file: '/public/404'
    end
  end

  def create
    cart = session[:cart].transform_keys { |k| k.to_sym }
    loan_requests = LoanRequest.find(cart[:requests])
    loan_offers = LoanOffer.find(cart[:offers])
    loan_requests.each do |lr|
      current_user.lent.create(loan_request_id: lr.id, borrower_id: lr.user_id) if lr.active
      borrower = User.find(lr.user_id)
      UserNotifier.contract_notice(current_user, borrower, current_user.email).deliver_now
      UserNotifier.contract_notice(borrower, current_user, borrower.email).deliver_now
      lr.update(active: false)
    end

    loan_offers.each do |lo|
      current_user.borrowed.create(loan_offer_id: lo.id, lender_id: lo.user_id) if lo.active
      lender = User.find(lo.user_id)
      UserNotifier.contract_notice(current_user, lender, current_user.email).deliver_now
      UserNotifier.contract_notice(lender, current_user, lender.email).deliver_now
      lo.update(active: false)
    end
    session[:cart]["requests"] = []
    session[:cart]["offers"] = []
    redirect_to user_contracts_path(current_user.username)
  end

  def destroy
    if current_admin?
      contract = Contract.find(params[:id])
      contract.update(active: false)
      redirect_to :back
    else
      flash[:error] = "Not allowed!"
    end
  end

  def index
    if current_admin?
      @active_contracts = Contract.all.where(active: true)
      @inactive_contracts = Contract.all.where(active: false)
    else
      render file: '/public/404'
    end
  end

  def reinstate
    if current_admin?
      contract = Contract.find(params[:id])
      contract.update(active: true)
      redirect_to :back
    else
      flash[:error] = "Not allowed!"
    end
  end

end
