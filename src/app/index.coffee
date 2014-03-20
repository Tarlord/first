_ = require 'lodash'
app = require('derby').createApp(module)
  .use(require 'derby-ui-boot')
  .use(require '../../ui/index.coffee')


# ROUTES #
# Derby routes are rendered on the client and the server
app.get '/', (page) ->
  page.render 'home'

app.get '/student', (page, model, params, next) ->

  questionsSelectedQuery = model.query 'questions' , {select: "True"}

  model.subscribe questionsSelectedQuery, (err) ->
    return next err if err

    questionsSelectedQuery.ref '_page.selectedQuestions'

    page.render 'student'

app.get '/professor', (page, model, params, next) ->

  questionsSelectedQuery = model.query 'questions' , {select: "True"}

  model.subscribe 'questions', 'answers', 'groups', questionsSelectedQuery, (err) ->
    return next err if err

    questionsSelectedQuery.ref '_page.selectedQuestions'

    model.at('questions').filter().ref '_page.questions'

    model.at('answers').filter().ref '_page.answers'

    model.at('groups').filter().ref '_page.groups'

    page.render 'professor'

# CONTROLLER FUNCTIONS #

app.fn 'student.addAnswer', () ->
  newAnswer = @model.del '_page.newAnswer'
  return unless newAnswer
  newAnswer.questionId = @model.get '_page.selectedQuestion.id'
  newAnswer.groupIds = null
  @model.add 'answers', newAnswer

app.fn 'student.selectQuestion', (e) ->
  selectedQuestion = e.get ':selectedQuestion'
  @model.set '_page.selectedQuestion', selectedQuestion

app.fn 'professor.addQuestion', () ->
  newQuestion = @model.del '_page.newQuestion'
  return unless newQuestion
  newQuestion.select = "False"
  @model.add 'questions', newQuestion

app.fn 'professor.removeQuestion', (e) ->
  question = e.get ':question'
  answers = @model.get 'answers'
  for answer in answers
    if answer.questionId == question.id
      @model.set answer.questionId, null
  @model.del 'questions.' + question.id

app.fn 'professor.addGroup', () ->
  newGroup = @model.del '_page.newGroup'
  return unless newGroup
  newGroup.questionId = @model.get '_page.activeQuestion.id'
  @model.add 'groups', newGroup

app.fn 'professor.removeGroup', (e) ->
  group = e.get ':group'
  @model.del 'groups.' + group.id

app.fn 'professor.removeAnswer', (e) ->
  answer = e.get ':answer'
  @model.del 'answers.' + answer.id

app.fn 'professor.selectQuestion', (e) ->
  question = e.get ':selectedQuestion'
  @model.set '_page.selectedAnswer', null
  @model.set '_page.activeQuestion', question

app.fn 'professor.selectGroup', (e) ->
  group = e.get ':group'
  selectedAnswer = @model.get '_page.selectedAnswer'
  @model.push 'answers.' + selectedAnswer.id + '.groupIds', group.id

app.fn 'professor.selectAnswer', (e) ->
  answer =e.get ':answer'
  @model.set '_page.selectedAnswer', answer

app.fn 'professor.removeFromGroup', (e) ->
  index = null
  group = e.get ':group'
  selectedAnswer = @model.get '_page.selectedAnswer'
  result = @model.get 'answers.' + selectedAnswer.id + '.groupIds'
  for key, value of result
    if value == group.id
      index = key
  @model.remove 'answers.'+selectedAnswer.id+'.groupIds', index
