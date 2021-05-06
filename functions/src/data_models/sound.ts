export class FirestoreSound {
  static initDocData({
    name,
    tags,
    description,
    explicit,
  }: {
    name: string;
    tags: string[];
    description: string;
    explicit: boolean;
  }): { [k: string]: unknown } {
    return {};
  }
}
