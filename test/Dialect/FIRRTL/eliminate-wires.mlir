// RUN: circt-opt -pass-pipeline='builtin.module(firrtl.circuit(firrtl.module(firrtl-eliminate-wires)))' %s | FileCheck %s

firrtl.circuit "TopLevel" {

  // CHECK-LABEL: @TopLevel
  firrtl.module @TopLevel(in %source: !firrtl.uint<1>,
                             out %sink: !firrtl.uint<1>) {
    // CHECK-NOT: firrtl.wire
    %w = firrtl.wire : !firrtl.uint<1>
    firrtl.matchingconnect %w, %source : !firrtl.uint<1>
    %wn = firrtl.not %w : (!firrtl.uint<1>) -> !firrtl.uint<1>
    %x = firrtl.wire : !firrtl.uint<1>
    firrtl.matchingconnect %x, %wn : !firrtl.uint<1>
    firrtl.matchingconnect %sink, %x : !firrtl.uint<1>
    firrtl.matchingconnect %sink, %w : !firrtl.uint<1>
  }

  // CHECK-LABEL: @Foo
  firrtl.module private @Foo() {
    %a = firrtl.wire : !firrtl.uint<3>
    %b = firrtl.wire : !firrtl.uint<3>
    %invalid_ui3 = firrtl.invalidvalue : !firrtl.uint<3>
    firrtl.matchingconnect %b, %invalid_ui3 : !firrtl.uint<3>
    firrtl.matchingconnect %a, %b : !firrtl.uint<3>
    // CHECK: %[[inv:.*]] = firrtl.invalidvalue : !firrtl.uint<3>
    // CHECK-NEXT:  %b = firrtl.node %[[inv]] : !firrtl.uint<3>
    // CHECK-NEXT:  %a = firrtl.node %b : !firrtl.uint<3>
  }

  // CHECK-LABEL: @SvAttributesPreserved
  // Verify that sv.attributes set on a wire are propagated to the replacement
  // NodeOp. Previously EliminateWires dropped sv.attributes, causing
  // firrtl.AttributeAnnotation (Chisel's addAttribute()) to produce no output
  // in emitted SV.
  firrtl.module private @SvAttributesPreserved(in %source: !firrtl.uint<1>,
                                               out %sink: !firrtl.uint<1>) {
    // CHECK-NOT: firrtl.wire
    // CHECK: %w = firrtl.node
    // CHECK-SAME: sv.attributes = [#sv.attribute<"mark_debug = \22true\22">]
    %w = firrtl.wire {sv.attributes = [#sv.attribute<"mark_debug = \"true\"">]} : !firrtl.uint<1>
    firrtl.matchingconnect %w, %source : !firrtl.uint<1>
    firrtl.matchingconnect %sink, %w : !firrtl.uint<1>
  }
}
