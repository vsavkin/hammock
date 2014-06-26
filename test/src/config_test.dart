part of hammock_test;

testConfig() {
  describe("HammockConfig", () {
    it("returns a route for a resource type", () {
      final c = new HammockConfig();
      c.set({"type" : {"route" : "aaa"}});

      expect(c.route("type")).toEqual("aaa");
    });

    it("defaults route to the resource type", () {
      final c = new HammockConfig();

      expect(c.route("type")).toEqual("type");
    });

    it("returns a serializer for a resource type", () {
      final c = new HammockConfig();
      c.set({"type" : {"serializer" : "serializer"}});

      expect(c.serializer("type")).toEqual("serializer");
    });

    it("throws when there is no serializer", () {
      final c = new HammockConfig();

      expect(() => c.serializer("type")).toThrow();
    });

    it("returns a deserializer for a resource type", () {
      final c = new HammockConfig();
      c.set({"type" : {"deserializer" : "deserializer"}});

      expect(c.deserializer("type", [])).toEqual("deserializer");
    });

    it("returns a deserializer for a resource type (query)", () {
      final c = new HammockConfig();
      c.set({"type" : {"deserializer" : {"query" : "deserializer"}}});

      expect(c.deserializer("type", ['query'])).toEqual("deserializer");
    });

    it("returns null when there is no deserializer", () {
      final c = new HammockConfig();

      expect(c.deserializer("type", [])).toBeNull();
    });

    it("returns a resource type for an object type", () {
      final c = new HammockConfig();
      c.set({"resourceType" : {"type" : "someType"}});

      expect(c.resourceType("someType")).toEqual("resourceType");
    });

    it("throws when no resource type is found", () {
      final c = new HammockConfig();
      expect(() => c.resourceType("someType")).toThrowWith(message: "No resource type found");
    });
  });
}