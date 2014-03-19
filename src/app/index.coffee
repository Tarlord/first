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

    model.start 'answersByGroups', '_page.answersByGroups', '_page.answers', '_page.groups'

    page.render 'professor'

# CONTROLLER FUNCTIONS #

app.fn 'student.addAnswer', () ->
  newAnswer = @model.del '_page.newAnswer'
  return unless newAnswer
  newAnswer.questionId = @model.get '_page.selectedQuestion.id'
  newAnswer.groupId = null
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
  @model.del 'questions.' + question.id

app.fn 'professor.addGroup', () ->
  newGroup = @model.del '_page.newGroup'
  return unless newGroup
  @model.add 'groups', newGroup

app.fn 'professor.removeGroup', (e) ->
  group = e.get ':group'
  @model.del 'groups.' + group.id

app.fn 'professor.removeAnswer', (e) ->
  answer = e.get ':answer'
  @model.del 'answers.' + answer.id

app.on 'model', (model) ->
  model.fn 'answersByGroups', (answers) ->
    result = []
    groups = {}
    for answer in (answers || [])
      if groups[answer.groupId] == undefined
        groups[answer.groupId] = []
      groups[answer.groupId].push answer.id
    for key, value of groups
      result.push {groupId: key, answerIds: value}
    return  result
