(* Copyright (c) 2016-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree. *)

open Ast
open Core

type origin =
  | Class of { annotation: Type.t; class_attribute: bool }
  | Module of Reference.t
[@@deriving compare, eq, show, hash]

type mismatch = {
  actual: Type.t;
  actual_expressions: Expression.t list;
  expected: Type.t;
  due_to_invariance: bool
}
[@@deriving compare, eq, show, hash]

type missing_annotation = {
  name: Reference.t;
  annotation: Type.t option;
  given_annotation: Type.t option;
  evidence_locations: Location.Instantiated.t list;
  thrown_at_source: bool
}
[@@deriving compare, eq, show, sexp, hash]

type incompatible_type = {
  name: Reference.t;
  mismatch: mismatch;
  declare_location: Location.Instantiated.t
}
[@@deriving compare, eq, show, sexp, hash]

type invalid_argument =
  | Keyword of { expression: Expression.t; annotation: Type.t }
  | Variable of { expression: Expression.t; annotation: Type.t }
[@@deriving compare, eq, show, sexp, hash]

type precondition_mismatch =
  | Found of mismatch
  | NotFound of Type.t Type.Callable.Parameter.t
[@@deriving compare, eq, show, sexp, hash]

type override =
  | StrengthenedPrecondition of precondition_mismatch
  | WeakenedPostcondition of mismatch
[@@deriving compare, eq, show, sexp, hash]

type unpack_problem =
  | UnacceptableType of Type.t
  | CountMismatch of int
[@@deriving compare, eq, sexp, show, hash]

type type_variable_origin =
  | ClassToplevel
  | Define
  | Toplevel
[@@deriving compare, eq, sexp, show, hash]

type type_variance_origin =
  | Parameter
  | Return
[@@deriving compare, eq, sexp, show, hash]

type illegal_action_on_incomplete_type =
  | Naming
  | Calling
  | AttributeAccess of Identifier.t
[@@deriving compare, eq, sexp, show, hash]

type override_kind =
  | Method
  | Attribute
[@@deriving compare, eq, sexp, show, hash]

type invalid_inheritance =
  | Class of Identifier.t
  | NonMethodFunction of Identifier.t
[@@deriving compare, eq, sexp, show, hash]

type invalid_override_kind =
  | Final
  | StaticSuper
  | StaticOverride
[@@deriving compare, eq, sexp, show, hash]

type invalid_assignment_kind =
  | Final of Reference.t
  | ClassVariable of { class_variable: Identifier.t; class_name: Identifier.t }
  | ReadOnly of Reference.t
[@@deriving compare, eq, sexp, show, hash]

type invalid_type_kind =
  | FinalNested of Type.t
  | FinalParameter of Identifier.t
  | InvalidType of Type.t
  | NestedTypeVariables of Type.Variable.t
[@@deriving compare, eq, sexp, show, hash]

type missing_overload_kind =
  | Implementation of Reference.t
  | SingleOverload of Reference.t
[@@deriving compare, eq, sexp, show, hash]

type incompatible_overload_kind =
  | ReturnType of
      { implementation_annotation: Type.t;
        name: Reference.t;
        overload_annotation: Type.t
      }
  | Unmatchable of
      { name: Reference.t;
        matched_location: Location.t;
        unmatched_location: Location.t
      }
[@@deriving compare, eq, sexp, show, hash]

type unawaited_awaitable = {
  references: Reference.t list;
  expression: Expression.t
}
[@@deriving compare, eq, sexp, show, hash]

type kind =
  | AnalysisFailure of Type.t
  | IllegalAnnotationTarget of Expression.t
  | ImpossibleIsinstance of { expression: Expression.t; mismatch: mismatch }
  | IncompatibleAttributeType of { parent: Type.t; incompatible_type: incompatible_type }
  | IncompatibleAwaitableType of Type.t
  | IncompatibleConstructorAnnotation of Type.t
  | IncompatibleParameterType of
      { name: Identifier.t option;
        position: int;
        callee: Reference.t option;
        mismatch: mismatch
      }
  | IncompatibleReturnType of
      { mismatch: mismatch;
        is_implicit: bool;
        is_unimplemented: bool;
        define_location: Location.t
      }
  | IncompatibleVariableType of incompatible_type
  | IncompatibleOverload of incompatible_overload_kind
  | IncompleteType of
      { target: Expression.t;
        annotation: Type.t;
        attempted_action: illegal_action_on_incomplete_type
      }
  | InconsistentOverride of
      { overridden_method: Identifier.t;
        parent: Reference.t;
        override: override;
        override_kind: override_kind
      }
  | InvalidArgument of invalid_argument
  | InvalidMethodSignature of { annotation: Type.t option; name: Identifier.t }
  | InvalidType of invalid_type_kind
  | InvalidTypeParameters of Resolution.type_parameters_mismatch
  | InvalidTypeVariable of { annotation: Type.Variable.t; origin: type_variable_origin }
  | InvalidTypeVariance of { annotation: Type.t; origin: type_variance_origin }
  | InvalidInheritance of invalid_inheritance
  | InvalidOverride of { parent: Identifier.t; decorator: invalid_override_kind }
  | InvalidAssignment of invalid_assignment_kind
  | MissingArgument of
      { callee: Reference.t option;
        parameter: AnnotatedSignature.missing_argument
      }
  | MissingAttributeAnnotation of { parent: Type.t; missing_annotation: missing_annotation }
  | MissingGlobalAnnotation of missing_annotation
  | MissingOverloadImplementation of Reference.t
  | MissingParameterAnnotation of missing_annotation
  | MissingReturnAnnotation of missing_annotation
  | MutuallyRecursiveTypeVariables of Reference.t option
  | NotCallable of Type.t
  | ProhibitedAny of missing_annotation
  | RedundantCast of Type.t
  | RevealedType of { expression: Expression.t; annotation: Type.t }
  | TooManyArguments of { callee: Reference.t option; expected: int; provided: int }
  | Top
  | TypedDictionaryAccessWithNonLiteral of Identifier.t list
  | TypedDictionaryKeyNotFound of { typed_dictionary_name: Identifier.t; missing_key: string }
  | UndefinedAttribute of { attribute: Identifier.t; origin: origin }
  | UndefinedImport of Reference.t
  | UndefinedName of Reference.t
  | UndefinedType of Type.t
  | UnexpectedKeyword of { name: Identifier.t; callee: Reference.t option }
  | UninitializedAttribute of { name: Identifier.t; parent: Type.t; mismatch: mismatch }
  | AbstractClassInstantiation of { class_name: Reference.t; method_names: Identifier.t list }
  | Unpack of { expected_count: int; unpack_problem: unpack_problem }
  | UnusedIgnore of int list
  (* Additional errors. *)
  | Deobfuscation of Source.t
  | UnawaitedAwaitable of unawaited_awaitable
[@@deriving compare, eq, show, hash]

include BaseError.Error with type kind := kind

module Set : Set.S with type Elt.t = t

val weaken_literals : kind -> kind

val due_to_analysis_limitations : t -> bool

val due_to_mismatch_with_any : Resolution.t -> t -> bool

val less_or_equal : resolution:Resolution.t -> t -> t -> bool

val join : resolution:Resolution.t -> t -> t -> t

val meet : resolution:Resolution.t -> t -> t -> t

val widen : resolution:Resolution.t -> previous:t -> next:t -> iteration:int -> t

val join_at_define : resolution:Resolution.t -> t list -> t list

val join_at_source : resolution:Resolution.t -> t list -> t list

val deduplicate : t list -> t list

val filter : configuration:Configuration.Analysis.t -> resolution:Resolution.t -> t list -> t list

val suppress : mode:Source.mode -> resolution:Resolution.t -> t -> bool

val dequalify : Reference.t Reference.Map.t -> resolution:Resolution.t -> t -> t

val create_mismatch
  :  resolution:Resolution.t ->
  actual:Type.t ->
  actual_expression:Expression.t option ->
  expected:Type.t ->
  covariant:bool ->
  mismatch
