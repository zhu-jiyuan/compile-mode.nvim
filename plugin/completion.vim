let s:command_completions = {
    \ 'go': {
    \   'build': [],
    \   'run': [],
    \   'mod': ['tidy', 'vendor', 'download', 'edit', 'graph', 'init', 'verify', 'why'],
    \   'test': [],
    \   'get': [],
    \   'install': [],
    \   'fmt': [],
    \   'vet': [],
    \ },
    \ 'docker': {
    \   'build': [],
    \   'run': [],
    \   'ps': [],
    \   'images': [],
    \   'pull': [],
    \   'push': [],
    \   'stop': [],
    \   'rm': [],
    \   'rmi': [],
    \   'exec': [],
    \   'logs': [],
    \ },
    \ 'git': {
    \   'add': [],
    \   'commit': [],
    \   'push': [],
    \   'pull': [],
    \   'status': [],
    \   'log': [],
    \   'branch': [],
    \   'checkout': [],
    \   'merge': [],
    \   'rebase': [],
    \   'diff': [],
    \   'clone': [],
    \   'remote': ['add', 'remove', 'rename', 'set-url', 'show', 'prune'],
    \   'fetch': [],
    \   'tag': [],
    \ }
    \ }

function! CompileInputComplete(ArgLead, CmdLine, CursorPos)
  let parts = split(a:CmdLine, '\s\+')
  " The last part is the argument we are trying to complete, so don't include it in the traversal path
  if a:CmdLine[-1:] !=# ' '
    let parts = parts[:-2]
  endif

  let completion_source = s:command_completions
  for part in parts
    if type(completion_source) == type({}) && has_key(completion_source, part)
      let completion_source = completion_source[part]
    else
      " Can't go deeper, so no custom completions available
      let completion_source = v:null
      break
    endif
  endfor

  if type(completion_source) == type({})
    return keys(completion_source)
  elseif type(completion_source) == type([])
    if !empty(completion_source)
      return completion_source
    endif
  endif

  " Fallback to default if no custom completions were found or list was empty
  let Results = getcompletion('!' . a:CmdLine, 'cmdline')
  return Results
endfunction

function! CompileInputCompleteWord(ArgLead, CmdLine, CursorPos)
	let Results = getcompletion('!' . a:CmdLine, 'cmdline')
	return Results
endfunction
