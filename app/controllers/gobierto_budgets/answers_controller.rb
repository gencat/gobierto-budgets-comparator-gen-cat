module GobiertoBudgets
  class AnswersController < GobiertoBudgets::ApplicationController
    respond_to :js

    def create
      @budget_line = GobiertoBudgets::BudgetLine.new answer_params.slice(:year, :code, :place_id, :area_name, :kind)
      answer = GobiertoBudgets::Answer.new answer_params
      answer.user_id = logged_in? ? current_user.id : nil
      answer.temporary_user_id = logged_in? ? nil : session.id
      if answer.save
        render question_handler_template(answer)
      else
        render 'error'
      end
    end

    private

    def answer_params
      params.require(:answer).permit(:question_id, :answer_text, :place_id, :kind, :area_name, :year, :code)
    end

    def question_handler_template(answer)
      if answer.question_id == 1
        if answer.answer_text == 'No'
          'question_1_answer_no'
        else
          'question_1_answer_yes'
        end
      elsif answer.question_id == 2
        'question_2'
      end
    end
  end
end
