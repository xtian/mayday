%{
  configs: [
    %{
      name: "default",
      files: %{
        excluded: [~r"/_build/", ~r"/deps/", ~r"/assets/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Design.DuplicatedCode, false},
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.SinglePipe, allow_0_arity_functions: true},
        {Credo.Check.Readability.StrictModuleLayout, []},
        {Credo.Check.Refactor.ABCSize, false},
        {Credo.Check.Refactor.AppendSingleItem, []},
        {Credo.Check.Refactor.DoubleBooleanNegation, []},
        {Credo.Check.Refactor.NegatedIsNil, []},
        {Credo.Check.Refactor.Nesting, max_nesting: 4},
        {Credo.Check.Refactor.PipeChainStart,
         excluded_argument_types: [:atom, :boolean, :fn, :number, :regex],
         excluded_functions: ["from"]},
        {Credo.Check.Warning.MapGetUnsafePass, []},
        {Credo.Check.Warning.UnsafeToAtom, []}
      ]
    }
  ]
}
