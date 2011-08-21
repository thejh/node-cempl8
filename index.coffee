fs = require 'fs'

simpleSplit = (str, delimiter) ->
  i = str.indexOf delimiter
  if i is -1
    [str]
  else
    [str.slice(0, i), str.slice(i+1)]

# slooooow!
replaceAll = (haystack, wrongNeedle, rightNeedle) ->
  while ~haystack.indexOf wrongNeedle
    haystack = haystack.replace wrongNeedle, rightNeedle
  haystack

copy = (src, dst) ->
  for key in Object.keys src
    dst[key] = src[key]
  dst

readMacroFile = (name, cb) ->
  fs.readFile name, 'utf8', (err, content) ->
    lines = content.split '\n'
    lineGroups = [[lines.shift()]]
    lines.forEach (line) ->
      if line[0] is ' '
        lineGroups[lineGroups.length-1].push line.trim()
      else
        lineGroups.push [line.trim()]
    methods = {}
    lineGroups.forEach (group) ->
      [type, firstLine] = simpleSplit group.shift(), " "
      return unless firstLine
      [name, firstLine] = simpleSplit firstLine.trim(), "{"
      name = name.trim()
      if firstLine
        [args, firstLine] = simpleSplit firstLine, "}"
        args = args.trim().split(",").map((str) -> str.trim())
        code = firstLine.trim()
      if !!code is !!group.length
        throw new Error('either everything on one line or no code on the first one')
      if not code
        code = group.join '\n'
      methods[name] = switch type
        when "complex"
          eval "(function(args){#{code}})"
        when "simple"
          (argDatas) ->
            result = code
            for arg, argI in args
              argData = argDatas[argI]
              result = replaceAll result, '#{'+arg+'}', argData
            result
        else
          throw new Error "unknown type #{type}"
    cb methods

compile = (macroFileNames, codeFileNames) ->
  macros = {}
  codeFiles = {}
  proceed = -> doCompile macros, codeFiles
  todo = 0
  for macroFileName in macroFileNames
    todo++
    readMacroFile macroFileName, (someMacros) ->
      copy someMacros, macros
      todo--
      proceed() if not todo
  for codeFileName in codeFileNames
    todo++
    fs.readFile "#{codeFileName}+", 'utf8', (err, content) ->
      codeFiles[codeFileName] = content
      todo--
      proceed() if not todo

nextIndexOf = (str, i, needle) ->
  subResult = str.slice(i).indexOf needle
  if ~subResult
    i + subResult
  else
    -1

spliceStr = (str, start, end, replacement) ->
  str.slice(0, start) + replacement + str.slice(end)

doCompile = (macros, codeFiles) ->
  for fileName, code of codeFiles
    for i in [code.length-1..0]
      if code[i] is '$' is code[i+1]
        openI = nextIndexOf code, i, '{{'
        closeI = nextIndexOf code, i, '}}'
        name = code.slice i+2, openI
        macro = macros[name]
        args = code.slice(openI+2, closeI).split ',,'
        code = spliceStr code, i, closeI+2, macro args
    fs.writeFile fileName, code

compile ['macros'], ['test.js']
