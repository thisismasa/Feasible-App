#!/usr/bin/env python3
"""
Claude AI Terminal Chat
Interactive chat with Claude AI in your terminal
"""

import anthropic
import os
import sys

def get_api_key():
    """Get API key from environment or prompt user"""
    api_key = os.environ.get("ANTHROPIC_API_KEY")

    if not api_key:
        print("⚠️  API key not found!")
        print("\nPlease set your API key:")
        print("1. Get key from: https://console.anthropic.com/")
        print("2. Run: $env:ANTHROPIC_API_KEY = 'your-key-here'")
        print("3. Or edit this file and add your key\n")

        api_key = input("Or enter your API key now: ").strip()

        if not api_key:
            print("❌ No API key provided. Exiting.")
            sys.exit(1)

    return api_key

def interactive_chat():
    """Run interactive chat with Claude"""

    # Get API key
    try:
        api_key = get_api_key()
        client = anthropic.Anthropic(api_key=api_key)
    except Exception as e:
        print(f"❌ Error initializing Claude: {e}")
        sys.exit(1)

    # Welcome message
    print("\n" + "="*60)
    print("🤖 Claude AI Terminal Chat".center(60))
    print("="*60)
    print("\nCommands:")
    print("  - Type your message to chat")
    print("  - 'clear' or 'reset' - Start new conversation")
    print("  - 'exit', 'quit', or 'bye' - Exit chat")
    print("="*60 + "\n")

    # Conversation history
    conversation = []

    while True:
        try:
            # Get user input
            user_message = input("You: ").strip()

            # Handle empty input
            if not user_message:
                continue

            # Exit commands
            if user_message.lower() in ['exit', 'quit', 'bye', 'q']:
                print("\n👋 Goodbye! Thanks for chatting with Claude.\n")
                break

            # Clear/Reset conversation
            if user_message.lower() in ['clear', 'reset', 'new']:
                conversation = []
                print("\n🔄 Conversation cleared. Starting fresh!\n")
                continue

            # Help command
            if user_message.lower() in ['help', '?']:
                print("\n📖 Commands:")
                print("  - clear/reset - Start new conversation")
                print("  - exit/quit - Exit chat")
                print("  - help - Show this message\n")
                continue

            # Add user message to conversation
            conversation.append({"role": "user", "content": user_message})

            # Show thinking indicator
            print("\n🤖 Claude is thinking...", end='', flush=True)

            # Get Claude's response
            response = client.messages.create(
                model="claude-opus-4-1-20250805",
                max_tokens=4096,
                messages=conversation
            )

            assistant_message = response.content[0].text

            # Add assistant response to conversation
            conversation.append({
                "role": "assistant",
                "content": assistant_message
            })

            # Clear thinking indicator and print response
            print("\r" + " "*30 + "\r", end='')  # Clear the line
            print(f"🤖 Claude:\n{assistant_message}\n")

            # Show token usage (if available)
            if hasattr(response, 'usage'):
                usage = response.usage
                print(f"   💡 Tokens: {usage.input_tokens} in, {usage.output_tokens} out")
                print()

        except KeyboardInterrupt:
            print("\n\n👋 Chat interrupted. Goodbye!\n")
            break

        except anthropic.AuthenticationError:
            print("\n❌ Authentication failed. Check your API key.")
            print("Get a key from: https://console.anthropic.com/\n")
            break

        except anthropic.RateLimitError:
            print("\n⏳ Rate limit reached. Please wait a moment.\n")
            continue

        except Exception as e:
            print(f"\n❌ Error: {str(e)}\n")
            continue

if __name__ == "__main__":
    try:
        interactive_chat()
    except Exception as e:
        print(f"\n❌ Fatal error: {e}\n")
        sys.exit(1)
