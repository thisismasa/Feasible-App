#!/usr/bin/env python3
"""
Claude AI CLI - Single Question Mode
Ask Claude a question directly from command line
"""

import anthropic
import os
import sys

def get_api_key():
    """Get API key from environment"""
    api_key = os.environ.get("ANTHROPIC_API_KEY")

    if not api_key:
        print("❌ Error: ANTHROPIC_API_KEY environment variable not set")
        print("\nTo set your API key:")
        print("  PowerShell: $env:ANTHROPIC_API_KEY = 'your-key-here'")
        print("  CMD: set ANTHROPIC_API_KEY=your-key-here")
        print("\nGet API key from: https://console.anthropic.com/")
        sys.exit(1)

    return api_key

def ask_claude(question, model="claude-opus-4-1-20250805"):
    """Ask Claude a single question"""

    api_key = get_api_key()

    try:
        client = anthropic.Anthropic(api_key=api_key)

        response = client.messages.create(
            model=model,
            max_tokens=4096,
            messages=[
                {"role": "user", "content": question}
            ]
        )

        return response.content[0].text, response.usage

    except anthropic.AuthenticationError:
        print("❌ Authentication failed. Check your API key.")
        sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)

def main():
    """Main CLI function"""

    # Check for arguments
    if len(sys.argv) < 2:
        print("Claude AI CLI - Single Question Mode")
        print("\nUsage:")
        print('  python claude-cli.py "Your question here"')
        print('\nExamples:')
        print('  python claude-cli.py "Explain recursion"')
        print('  python claude-cli.py "Write a Python function to sort a list"')
        print('\nFor interactive chat, use: python claude-chat.py')
        sys.exit(1)

    # Get question from command line arguments
    question = ' '.join(sys.argv[1:])

    print("🤖 Asking Claude...\n")
    print("-" * 60)

    # Ask Claude
    answer, usage = ask_claude(question)

    # Print answer
    print(answer)
    print("-" * 60)

    # Show token usage
    if usage:
        print(f"\n💡 Tokens used: {usage.input_tokens} input, {usage.output_tokens} output")

if __name__ == "__main__":
    main()
