function! CompileInputComplete(ArgLead, CmdLine, CursorPos)
  let Results = getcompletion('!' . a:CmdLine, 'cmdline')
  return Results
endfunction

function! CompileInputCompleteWord(ArgLead, CmdLine, CursorPos)
	let Results = getcompletion('!' . a:CmdLine, 'cmdline')
	return Results
endfunction
