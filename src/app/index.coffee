app = require('derby').createApp(module)
  .use(require 'derby-ui-boot')
  .use(require '../../ui/index.coffee')
  .use(require 'lodash')


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

  userId = model.get '_session.userId'

  user = model.at 'users.' + userId

  questionsQuery = model.query 'questions', {userId}

  questionsSelectedQuery = model.query 'questions' , {select: "True"}

  answersQuery = model.query 'answers', {userId}

  groupsQuery = model.query 'groups', {userId}

  model.subscribe user, questionsQuery, questionsSelectedQuery, answersQuery, groupsQuery, (err) ->
    return next err if err

    model.ref '_page.user', user

    questionsQuery.ref '_page.questions'

    questionsSelectedQuery.ref '_page.selectedQuestions'

    answersQuery.ref '_page.answers'

    groupsQuery.ref '_page.groups'

    model.start 'answersByGroups', '_page.answersByGroups', '_page.answers', '_page.groups'

    page.render 'professor'

# CONTROLLER FUNCTIONS #

app.fn 'student.addAnswer', () ->
  newAnswer = @model.del '_page.newAnswer'
  return unless newAnswer
  newAnswer.userId = @model.get '_session.userId'
  newAnswer.question = @model.get '_page.selectedQuestion.text'
  @model.add 'answers', newAnswer

app.fn 'student.selectQuestion', (e) ->
  selectedQuestion = e.get ':selectedQuestion'
  @model.set '_page.selectedQuestion', selectedQuestion

app.fn 'professor.addQuestion', () ->
  newQuestion = @model.del '_page.newQuestion'
  return unless newQuestion
  newQuestion.userId = @model.get '_session.userId'
  newQuestion.select = "False"
  @model.add 'questions', newQuestion

app.fn 'professor.removeQuestion', (e) ->
  question = e.get ':question'
  @model.del 'questions.' + question.id

app.fn 'professor.addGroup', () ->
  newGroup = @model.del '_page.newGroup'
  return unless newGroup
  newGroup.userId = @model.get '_session.userId'
  @model.add 'groups', newGroup

app.fn 'professor.removeGroup', (e) ->
  group = e.get ':group'
  @model.del 'groups.' + group.id

app.fn 'professor.removeAnswer', (e) ->
  answer = e.get ':answer'
  @model.del 'answers.' + answer.id

app.on 'model', (model) ->
  model.fn 'answersByGroups', (answers, groups) ->
    result = {}
    preresult = []
    for group in groups
      for answer in answers
        if answer.groupId == group.id
          result = {name: group.text, text: answer.note, group: group.text, student: answer.name, question: answer.question}
          preresult.push result

    return  Object.keys preresult