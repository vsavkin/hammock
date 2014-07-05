part of hammock_test;

testConfig() {
  describe("HammockConfig", () {
    setUpAngular();

    it("returns a route for a resource type", (HammockConfig c) {
      c.set({"type" : {"route" : "aaa"}});

      expect(c.route("type")).toEqual("aaa");
    });

    it("defaults the route to the given resource type", (HammockConfig c) {
      expect(c.route("type")).toEqual("type");
    });

    it("returns a serializer for a resource type", (HammockConfig c) {
      c.set({"type" : {"serializer" : "serializer"}});

      expect(c.serializer("type")).toEqual("serializer");
    });

    it("throws when there is no serializer", (HammockConfig c) {
      expect(() => c.serializer("type")).toThrow();
    });

    it("returns a deserializer for a resource type", (HammockConfig c) {
      c.set({"type" : {"deserializer" : "deserializer"}});

      expect(c.deserializer("type", [])).toEqual("deserializer");
    });

    it("returns a deserializer for a resource type (nested)", (HammockConfig c) {
      c.set({"type" : {"deserializer" : {"query" : "deserializer"}}});

      expect(c.deserializer("type", ['query'])).toEqual("deserializer");
    });

    it("returns null when there is no deserializer", (HammockConfig c) {
      expect(c.deserializer("type", [])).toBeNull();
    });

    it("returns a resource type for an object type", (HammockConfig c) {
      c.set({"resourceType" : {"type" : "someType"}});

      expect(c.resourceType("someType")).toEqual("resourceType");
    });

    it("throws when no resource type is found", (HammockConfig c) {
      expect(() => c.resourceType("someType")).toThrowWith(message: "No resource type found");
    });

    describe("when given types", () {
      registerBindings([_TestInjectable]);

      it("uses Injector to instantiate serializers and deserializers", (HammockConfig c) {
        c.set({
            "type" : {
                "serializer" : _TestInjectable,
                "deserializer" : _TestInjectable
            }
        });

        expect(c.serializer("type")).toBeA(_TestInjectable);
        expect(c.deserializer("type")).toBeA(_TestInjectable);
      });
    });
  });
}

class _TestInjectable {
  ObjectStore store;
  _TestInjectable(this.store);
}