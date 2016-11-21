module GobiertoBudgets
  class Answer < ActiveRecord::Base
    QUESTION_1_ANSWERS = ['Sí', 'No']
    QUESTION_2_ANSWERS = ['Poco', 'Apropiado', 'Mucho']

    def self.percentages_for_question(question_id, options)
      scoped = where({question_id: question_id}.merge(options))

      total = scoped.count
      groups = scoped.select('id, answer_text').group_by do |a|
        a.answer_text
      end

      Hash[groups.map do |answer_text, list|
        [answer_text, ((list.length.to_f * 100.0) / total).round(1)]
      end]
    end
  end
end
